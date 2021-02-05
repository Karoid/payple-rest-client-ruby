# frozen_string_literal: true

require_relative "payple/version"
require "httparty"

module Payple
  PAYPLE_HOST = "https://cpay.payple-rest-client-ruby.kr".freeze
  PAYPLE_TEST_HOST = "https://testcpay.payple-rest-client-ruby.kr".freeze

  class Config
    attr_accessor :cst_id
    attr_accessor :cust_key
    attr_accessor :refund_key
    attr_accessor :is_test_mode

    def initialize
      @api_key = nil
      @api_secret = nil
      @refund_key = nil
      @is_test_mode = false
    end
  end

  class << self
    def configure
      yield(config) if block_given?
    end

    def config
      @config ||= Config.new
    end

    def host
      if config.is_test_mode
        PAYPLE_TEST_HOST
      else
        PAYPLE_HOST
      end
    end


  end

end
