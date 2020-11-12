module Termplot
  module Producers
    class BaseProducer
      def initialize(options)
        @options = options
        @on_message_handler = -> {}
      end

      def on_message(&block)
        @on_message_handler = block
      end

      def run
        raise "Must be implemented"
      end

      private
      attr_reader :options, :on_message_handler

      def produce(value)
        if numeric?(value)
          on_message_handler.call(value.to_f)
        end
      end

      FLOAT_REGEXP = /^[-+]?[0-9]*\.?[0-9]+$/
      def numeric?(n)
        n =~ FLOAT_REGEXP
      end
    end
  end
end
