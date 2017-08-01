require 'dry-struct'
require 'dry-types'

module Callable
  class ServiceObject < Dry::Struct
    module Types
      include Dry::Types.module
    end

    class << self
      def call(*args)
        new(*args).call
      end

      def process(method)
      end
    end

    def call
    end
  end
end
