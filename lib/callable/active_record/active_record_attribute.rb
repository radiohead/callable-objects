# frozen_string_literal: true
module Virtus
  # Polymorphic class to use for coercing ActiveRecord models
  class ActiveRecordAttribute < Virtus::Attribute
    # Make ActiveRecord::Base default class for coercion
    @model_klass = ActiveRecord::Base

    def coerce(value)
      # Raise an error if we got something other than expected model class
      # Since there now way to coerce one ActiveRecord model into another
      raise Virtus::CoercionError.new(value.class, self) unless value.is_a?(primitive)

      # If we got here that means value is compatible,
      # let it through
      value
    end

    def primitive
      self.class.model_klass
    end

    class << self
      attr_accessor :model_klass

      def generate_for(model_klass)
        # Clone class to get a fresh one
        coercer = clone
        # Set the type of model we will be coercing with
        coercer.model_klass = model_klass
        # Return our clone that knows which class to compare with
        coercer
      end
    end
  end
end
