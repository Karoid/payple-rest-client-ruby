# frozen_string_literal: true

require_relative "payple/version"
require_relative "payple/cpay"
require_relative "payple/gpay"
require "httparty"

class Payple

  class << self
    def cpay
      @cpay ||= Payple::Cpay
    end
  
    def gpay
      @gpay ||= Payple::Gpay
    end

    def configure
      Payple::Cpay.configure
    end

    [:config, :host, :payment, :cert_confirm, :refund, :payer, :delete_payer, :payment_again, :auth, :auth_raw].each do |method_name|
      define_method method_name do |options|
        Payple::Cpay.public_send(method_name, options)
      end
    end
  end

end
