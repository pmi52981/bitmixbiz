# frozen_string_literal: true

require_relative 'bitmixbiz/version'

module Bitmixbiz
  API_HOST = 'bitmix.biz'.freeze
  API_TOR_HOST = 'bitmixbizymuphkc.onion'.freeze
  API_TESTNET_HOST = 'jnee3nwxjm7mqva5.onion'.freeze

  module Helpers
    def optionize(default_options, options)
      hash = default_options.merge(options)
      @options = OpenStruct.new hash
    end
  end
end

class Object
  def symbolize_hash_keys
    return self.inject({}){|memo,(k,v)| memo[k.to_sym] =  v.symbolize_hash_keys; memo} if self.is_a? Hash
    return self.inject([]){|memo,v    | memo           << v.symbolize_hash_keys; memo} if self.is_a? Array
    self
  end
end
require_relative 'bitmixbiz/mixer'
require_relative 'bitmixbiz/order'
