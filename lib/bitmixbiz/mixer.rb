# frozen_string_literal: true

require 'ostruct'
require 'net/http'
require 'uri'
require 'json'
require 'socksify/http'
require 'logger'

module Bitmixbiz
  class Mixer
    class MixError < ::StandardError; end
    class ArgumentError < MixError; end

    class ResponseError < MixError

      attr_reader :status_code, :message, :errors

      def initialize(status_code, message, errors = {})
        @status_code = status_code
        @message = message
        @errors = errors
      end

      def to_s
        out = +"#{self.class}: #{message}\n"
        out << "Response status: #{status_code}\n"
        out << "Errors: #{errors.values.join(',')}" unless errors.empty?
        out
      end
    end

    attr_reader :options, :active_host
    attr_accessor :logger

    include Helpers

    # @param [String] key Unique identifer for API
    # @param [Hash] options
    # Available +options+:
    #
    # +tor+ [Boolean], use API in TOR or not. Default: false
    # +testnet+ [Boolean]. Use testnet API or not
    # +socks_host+ [String]. Socks hostname
    # +socks_port+ [Int]. Socks port
    #
    # Example of usage:
    # mixer = Bitmixbiz::Mixer.new do |agent|
    #   agent.options.tor = true
    #   agent.options.socks_port = 9051
    #   agent.key = '123afde'
    # end
    # order = Bitmixbiz::Order.new tax: rand(0.4, 2.0)
    # response = mixer.mix! order

    def initialize(key = nil, options = {})
      @logger = Logger.new STDOUT
      @key = key
      def_opts = {
        tor: false,
        testnet: false,
        socks_host: '127.0.0.1',
        socks_port: 9050,
        api_host: API_HOST,
        api_tor_host: API_TOR_HOST,
        api_testnet_host: API_TESTNET_HOST
      }
      optionize(def_opts, options)
      yield self if block_given?
      @active_host =
          if @options.testnet
            @options.api_testnet_host
          elsif @options.tor
            @options.tor_host
          else
            @options.api_host
          end
    end

    def build_order(order_id)
      order = Order.new do |o|
        o.id = order_id
        o.instance_variable_set('@host', active_host)
      end
      view_order order
      order.instance_variable_set('@input_address', order.data[:order][:input_address])
      order
    end

    def letter_for_order(order_id)
      request "/order/letter/#{order_id}"

    rescue Exception => ex
      log ex.to_s, :fatal
      raise ex
    end
    # @param [Bitmixbiz::Order] order
    # Creating the order
    # If block given yields json response from Bitmix.biz
    def create_order(order)
      json = request '/order/create', :post, order.options.to_h
      order.id = json['id']
      order.instance_variable_set("@input_address", json['input_address'])
      order.instance_variable_set("@host", active_host)
      view_order order
      yield json if block_given?
      true
    rescue Exception => ex
      log ex.to_s, :fatal
      raise ex
    end

    def view_order(order)
      json = request "/order/view/#{order.id}"
      order.instance_variable_set("@data", json.symbolize_hash_keys)
      if order.input_address.nil?
        order.instance_variable_set('@input_address', order.data[:order][:input_address])
      end
    rescue Exception => ex
        log ex.to_s, :fatal
        raise ex
    end

    private

    def log(msg, level = 'debug')
      logger.send(level, msg) if logger
    end

    def error_handler(response)
      if response['content-type'].include?('application/json')
        json = JSON.parse(response.body)
        if json.is_a?(Hash)
          raise ResponseError.new response.code, json['message'], json['errors']
        else
          raise ResponseError.new response.code, json.is_a?(Array) ? json.join(',') : json.to_s
        end
      else
        raise MixError.new "Wrong response: #{response.class} - #{response.inspect}"
      end
    rescue
      raise ResponseError.new response.code, 'wrong response code'
    end

    # @param [String] path
    # @param [Symbol] method
    # @param [Hash] params
    def request(path, method = :get, params = {})
      uri = URI("http://#{@active_host}/api")
      uri.path += path
      req = prepare_request(method, uri)

      # Setting params only for post request.
      # Get request ignoring, because API doesn't have any query params

      req['Accept'] = 'application/json'
      req.body= convert_hash_to_string_params(params.merge(key: @key)) if method == :post

      http_klass = active_host.end_with?('onion') ? Net::HTTP.SOCKSProxy(options.socks_host, options.socks_port) : Net::HTTP

      http = http_klass.new uri.hostname, uri.port

      http.set_debug_output(@logger) if $DEBUG

      log "<- #{method.upcase} #{uri.path}", :info
      req.each {|k| log "<- #{k}: #{req[k]}", :debug}

      response = http.request req
      log "-> #{response.class} #{response.code}", :info
      response.each {|k| log "-> #{k}: #{response[k]}", :debug}
      error_handler(response) unless response.is_a?(Net::HTTPOK)

      if response['content-type'].include? 'application/json'
        JSON.parse response.body
      else
        response.body
      end
    end

    def convert_hash_to_string_params(hash)
      hash.inject([]) do |memo, data|
        if data[1].is_a?(Array)
          data[1].each {|s| memo << "#{data[0]}[]=#{s}"}
        else
          memo << "#{data[0]}=#{data[1]}"
        end
        memo
      end.join('&')
    end

    def prepare_request(method, uri)
      method == :post ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
    end
  end
end
