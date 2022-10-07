# frozen_string_literal: true

require "httparty"

module Payple::Cpay
  PAYPLE_HOST = "https://cpay.payple.kr".freeze
  PAYPLE_TEST_HOST = "https://democpay.payple.kr".freeze

  class Config
    attr_accessor :cst_id
    attr_accessor :cust_key
    attr_accessor :refund_key
    attr_accessor :is_test_mode
    attr_accessor :referer

    def initialize
      @cst_id = nil
      @cust_key = nil
      @refund_key = nil
      @is_test_mode = false
      @referer = nil
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

      url, payload = auth({PCD_PAYCHK_FLAG: "Y"})
      payload.merge!({PCD_PAYCHK_FLAG: "Y", PCD_PAY_TYPE: options.fetch(:pay_type),
                     PCD_PAY_OID: options.fetch(:oid), PCD_PAY_DATE: options.fetch(:pay_date)})
      payload.merge!(other_payloads)

      HTTParty.post(url, headers: headers, body: payload.to_json)
    end

    # Confirm CERT type payment
    # https://docs.payple.kr/card/pay/app-card
    # https://docs.payple.kr/card/pay/regular
    def cert_confirm(options = {})
      required_parameter = [:cert_url, :auth_key, :request_key]
      optional_parameter = [:payer_id]
      parameters = required_parameter + optional_parameter
      other_payloads = options.reject { |key| parameters.include?(key) }

      payload = {
        PCD_CST_ID: config.cst_id,
        PCD_CUST_KEY: config.cust_key,
        PCD_AUTH_KEY: options.fetch(:auth_key),
        PCD_PAY_REQKEY: options.fetch(:request_key),
      }
      if options[:payer_id]
        payload.merge!({PCD_PAYER_ID: options.fetch(:payer_id)})
      end
      payload.merge!(other_payloads)

      HTTParty.post(options.fetch(:cert_url), headers: headers, body: payload.to_json)
    end

    def refund(options = {})
      required_parameter = [:oid, :pay_date, :refund_total]
      other_payloads = options.reject { |key| required_parameter.include?(key) }

      url, payload = auth({PCD_PAYCANCEL_FLAG: "Y"})

      pay_date = options.fetch(:pay_date)
      pay_date = pay_date.strftime("%Y%m%d") if pay_date.respond_to?('strftime')

      payload.merge!({
        PCD_PAYCANCEL_FLAG: 'Y',
        PCD_REFUND_KEY: config.refund_key,
        PCD_PAY_OID: options.fetch(:oid),
        PCD_PAY_DATE: pay_date,
        PCD_REFUND_TOTAL: options.fetch(:refund_total).to_i
      })
      payload.merge!(other_payloads)

      HTTParty.post(url, headers: headers, body: payload.to_json)
    end

    def payer(options = {})
      required_parameter = [:payer_id]
      optional_parameter = [:payer_no]
      parameters = required_parameter + optional_parameter
      other_payloads = options.reject { |key| parameters.include?(key) }

      url, payload = auth({PCD_PAY_WORK: "PUSERINFO"})

      payload.merge!({
        PCD_PAYER_ID: options.fetch(:payer_id),
        PCD_PAYER_NO: options[:payer_no]
      })
      payload.merge!(other_payloads)

      HTTParty.post(url, headers: headers, body: payload.to_json)
    end

    def delete_payer(options = {})
      required_parameter = [:payer_id]
      optional_parameter = [:payer_no]
      parameters = required_parameter + optional_parameter
      other_payloads = options.reject { |key| parameters.include?(key) }

      url, payload = auth({PCD_PAY_WORK: "PUSERDEL"})

      payload.merge!({
        PCD_PAYER_ID: options.fetch(:payer_id),
        PCD_PAYER_NO: options[:payer_no]
      })
      payload.merge!(other_payloads)

      HTTParty.post(url, headers: headers, body: payload.to_json)
    end

    def payment_again(options = {})
      required_parameter = [:pay_type, :payer_id, :goods_name, :pay_total]
      optional_parameter = [:payer_no, :pay_month, :pay_year, :payer_name, :payer_email, :payer_hp]
      parameters = required_parameter + optional_parameter
      other_payloads = options.reject { |key| parameters.include?(key) }

      raise ArgumentError("Invalid pay_type: pay_type must by :card or :transfer") unless [:card, :transfer].include? options.fetch(:pay_type).to_sym

      if options[:pay_year].present? && options[:pay_month].present?
        url, payload = auth({PCD_REGULAR_FLAG: "Y", PCD_PAY_TYPE: options.fetch(:pay_type)})
        payload.merge!({
          PCD_REGULAR_FLAG: "Y",
          PCD_PAY_YEAR: options.fetch(:pay_year),
          PCD_PAY_MONTH: options.fetch(:pay_month)
        })
      else
        url, payload = auth({PCD_SIMPLE_FLAG: "Y", PCD_PAY_TYPE: options.fetch(:pay_type)})
        payload.merge!({
          PCD_SIMPLE_FLAG: "Y"
        })
      end

      payload.merge!({
        PCD_PAY_TYPE:    options.fetch(:pay_type),
        PCD_PAYER_ID:    options.fetch(:payer_id),
        PCD_PAY_GOODS:   options.fetch(:goods_name),
        PCD_PAY_TOTAL:   options.fetch(:pay_total).to_i,
        PCD_PAYER_NO:    options[:payer_no],
        PCD_PAYER_NAME:  options[:payer_name],
        PCD_PAYER_EMAIL: options[:payer_email],
        PCD_PAYER_HP:    options[:payer_hp],
      })
      payload.merge!(other_payloads)

      HTTParty.post(url, headers: headers, body: payload.to_json)
    end

    # authorization to Payple
    # 필수가 아닌 파라미터를 req_params로 넘겨주어야 한다
    # return values:
    #  - url
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
      required_parameter = [:referer]
      other_req_params = req_params.reject { |key| required_parameter.include?(key) }
      url = "#{host}/php/auth.php"
      payload = {
        "cst_id": config.cst_id,
        "custKey": config.cust_key
      }
      HTTParty.post(url, headers: headers, body: payload.merge(other_req_params).to_json).parsed_response
    end

    private

    def headers
      {
          'Content-Type': 'application/json; charset=utf-8',
          'Cache-Control': 'no-cache',
          'referer': config.referer
      }
    end

  end

end
