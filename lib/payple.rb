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
  end

end
