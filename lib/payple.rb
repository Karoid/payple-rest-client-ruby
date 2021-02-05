# frozen_string_literal: true

require_relative "payple/version"
require "httparty"

module Payple
  PAYPLE_HOST = "https://cpay.payple.kr".freeze
  PAYPLE_TEST_HOST = "https://testcpay.payple.kr".freeze

  class Config
    attr_accessor :cst_id
    attr_accessor :cust_key
    attr_accessor :refund_key
    attr_accessor :is_test_mode

    def initialize
      @cst_id = nil
      @cust_key = nil
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

    # Get host data
    def host
      if config.is_test_mode
        PAYPLE_TEST_HOST
      else
        PAYPLE_HOST
      end
    end

    # Get Payment Info
    # https://docs.payple.kr/card/result/search
    # https://docs.payple.kr/bank/result/search
    def payment(options = {})
      required_parameter = [:pay_type, :oid, :pay_date]
      other_payloads = options.reject { |key| required_parameter.include?(key) }

      # validate pay_type
      raise ArgumentError("Invalid pay_type: pay_type must by :card or :transfer") unless [:card, :transfer].include? options.fetch(:pay_type).to_sym

      uri, payload = auth({PCD_PAYCHK_FLAG: "Y"})
      payload.merge({PCD_PAYCHK_FLAG: "Y", PCD_PAY_TYPE: options.fetch(:pay_type),
                     PCD_PAY_OID: options.fetch(:oid), PCD_PAY_DATE: options.fetch(:pay_date)}).merge(other_payloads)

      puts uri, payload

      HTTParty.post(uri, headers: headers, body: payload.to_json)
    end

    # authorization to Payple
    # 필수가 아닌 파라미터를 req_params로 넘겨주어야 한다
    # return values:
    #  - uri
    #  - next request default payload data
    def auth(req_params = {})
      result = auth_raw(req_params)

      raise "Invalid Customer Configuration: #{result["result_msg"]}" unless result["result"] === 'success'
      return_payload = {
          PCD_CST_ID: result["cst_id"],
          PCD_CUST_KEY: result["custKey"],
          PCD_AUTH_KEY: result["AuthKey"]
      }
      return result["return_url"], return_payload
    end

    def auth_raw(req_params = {})
      uri = "#{host}/php/auth.php"
      payload = {
          "cst_id": config.cst_id,
          "custKey": config.cust_key
      }
      HTTParty.post(uri, headers: headers, body: payload.merge(req_params).to_json).parsed_response
    end

    private

    def headers
      {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache'
      }
    end

  end

end
