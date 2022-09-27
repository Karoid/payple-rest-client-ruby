# frozen_string_literal: true

require "httparty"

module Payple::Gpay
  PAYPLE_HOST = "https://api.payple.kr".freeze
  PAYPLE_TEST_HOST = "https://demo-api.payple.kr".freeze

  class Config
    attr_accessor :service_id
    attr_accessor :service_key
    attr_accessor :is_test_mode
    attr_accessor :referer

    attr_accessor :token
    attr_accessor :token_expires_in

    def initialize
      @service_id = nil
      @service_key = nil
      @is_test_mode = false
      @referer = nil
      @token = nil
      @token_expires_in = Time.now
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
    # https://developer.payple.kr/95003782-646b-4481-847d-30d116b367a7
    def payment(options = {})
      required_parameter = [:service_oid, :pay_id]
      other_payloads = options.reject { |key| required_parameter.include?(key) }

      # validate params
      raise ArgumentError("Invalid params: service_oid or pay_id parameter needed") unless options.fetch(:service_oid).present? || options.fetch(:pay_id).present?

      url = "#{host}/gpay/paymentResult"

      payload = {
        "service_id": config.service_id
      }
      payload.merge!({"service_oid": options.fetch(:service_oid)}) if options.fetch(:service_oid)
      payload.merge!({"pay_id": options.fetch(:pay_id)}) if options.fetch(:pay_id)
      payload.merge!(other_payloads)

      HTTParty.post(url, headers: headers, body: payload.to_json)
    end

    # refund
    # https://developer.payple.kr/global/payment-cancel
    def refund(options = {})
      required_parameter = [:service_oid, :pay_id, :comments, :totalAmount, :currency, :resultUrl]
      other_payloads = options.reject { |key| required_parameter.include?(key) }

      payment_data = payment(options.permit { |key| [:service_oid, :pay_id].include?(key) })

      url = "#{host}/gpay/cancel"

      payload = {
        service_id: config.service_id,
        comments: remove_invalid_chars(payment_data.fetch(:comments)),
        totalAmount: options.fetch(:totalAmount),
        currency: options[:currency] || 'USD',
        resultUrl: options.fetch(:resultUrl)
      }
      payload.merge!(other_payloads)

      HTTParty.post(url, headers: headers, body: payload.to_json)
    end

    # pay again
    # service_oid를 제공하거나, billing_key를 제공해야 한다
    def payment_again(options = {})
      required_parameter = [:comments, :totalAmount, :currency]
      optional_parameter = [:billing_key, :service_oid, :securityCode, :firstName, :lastName, :country, :administrativeArea, :locality, :address1, :postalCode, :email, :phoneNumber, :resultUrl]
      parameters = required_parameter + optional_parameter
      other_payloads = options.reject { |key| parameters.include?(key) }

      if options[:service_oid].present?
        payment_data = payment(service_oid: options.fetch(:service_oid))
        options.billing_key = payment_data.fetch(:billing_key)
      end

      raise ArgumentError("Invalid parameter: billing_key or service_oid must be included") if options[:billing_key].nil?

      url = "#{host}/gpay/billingKey"

      payload = {
        service_id: config.service_id,
        service_oid: options[:service_oid],
        comments: remove_invalid_chars(payment_data.fetch(:comments)),
        billing_key: options.fetch(:billing_key),
        securityCode: options[:securityCode],
        totalAmount: options.fetch(:totalAmount),
        currency: options[:currency] || 'USD',
        firstName: options[:firstName],
        lastName: options[:lastName],
        country: options[:country],
        administrativeArea: options[:administrativeArea],
        locality: options[:locality],
        address1: options[:address1],
        postalCode: options[:postalCode],
        email: options[:email],
        phoneNumber: options[:phoneNumber],
        resultUrl: options.fetch(:resultUrl)
      }
      payload.delete_if{ |k,v| optional_parameter.include?(k) && v.nil? }

      HTTParty.post(url, headers: headers, body: payload.to_json)
    end

    # authorize
    def auth(req_params = {})
      res = request_token(req_params)
      case res.code
      when 404
        raise res.to_s
      when 500
        raise res.to_s
      end
      raise "Invalid Authorize Response : #{res["message"]}" unless res["result"] === 'T0000'
      return res.to_h.merge({service_id: config.service_id})
    end

    def get_token(req_params = {})
      if config.token_expires_in < Time.now
        request_send_time = Time.now
        token_padding_time = 10.seconds
        res = auth(req_params)
        config.token = res["access_token"]
        expires_in_seconds = res["expires_in"]
        config.token_expires_in = request_send_time + expires_in_seconds.to_i.seconds - token_padding_time
      end
      return config.token
    end

    def request_token(req_params = {})
      required_parameter = [:code]
      req_params[:code] ||= SecureRandom.alphanumeric(10)
      other_req_params = req_params.reject { |key| required_parameter.include?(key) }
      url = "#{host}/gpay/oauth/1.0/token"
      payload = {
        "service_id": config.service_id,
        "service_key": config.service_key,
        "code": req_params[:code]
      }
      if config.is_test_mode
        payload.merge({
          "payCls": "demo"
        })
      end
      HTTParty.post(url, headers: headers_without_token, body: payload.merge(other_req_params).to_json)
    end

    private

    def headers_without_token
      {
          'Content-Type': 'application/json; charset=utf-8',
          'Cache-Control': 'no-cache',
          'referer': config.referer
      }
    end

    def headers(req_params = {})
      {
        'Content-Type': 'application/json; charset=utf-8',
        'Cache-Control': 'no-cache',
        'referer': config.referer,
        'Authorization': "Bearer #{get_token(req_params)}"
      }
    end

    def remove_invalid_chars(comment)
      return comment.gsub(/[^ㄱ-힣A-z ',\-_&\.]/,'_')
    end
  end

  
end