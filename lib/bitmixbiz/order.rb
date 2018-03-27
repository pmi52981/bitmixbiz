# frozen_string_literal: true

module Bitmixbiz
  class Order

    include Helpers

    attr_accessor :options, :id
    attr_reader :data, :input_address
    # @param [String | NilClass] key
    # @param [Hash] options
    #
    # Order initialize
    # Available +options+:
    # +tax+ [Float], between 0.4..4. Default: 0.4
    # +code+ [String], Last code, received from API. Default: nil
    # +delay+ [Float], between 1..24. Default: 24
    # +address+ [Array]. Bitcoin addresses
    # +ref_key+ [String], ref key from partner panel

    def initialize(options = {})
      @id = nil
      @input_address = nil
      @host = Bitmixbiz::API_HOST
      @data = {}
      optionize({ tax: 0.4, delay: 24, address: [], randomize: 0 }, options)
      yield self if block_given?
    end

    def link
      "http://#{@host}/api/order/view/#{id}"
    end

    def to_h
      {
          input_address: input_address,
          id: id,
          data: @data
      }
    end
  end
end
