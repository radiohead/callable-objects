# frozen_string_literal: true
module Virtus
  # :nodoc:
  class RailsParams < Virtus::Attribute
    def coerce(value)
      if value.is_a?(HashWithIndifferentAccess)
        value
      else
        hash = value.respond_to?(:to_h) ? value.to_h : {}
        HashWithIndifferentAccess.new(hash)
      end
    end
  end
end
