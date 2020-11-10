module Termplot
  module Producers
    class BaseProducer
      def initialize(queue, options)
        @options = options
        @queue = queue
        @consumer = nil
      end

      def register_consumer(consumer)
        @consumer = consumer
      end

      def shift
        queue.shift
      end

      def closed?
        queue.closed?
      end

      def close
        queue.close
      end

      private
      attr_reader :queue, :consumer, :options

      def produce(value)
        if numeric?(value)
          queue << value.to_f
          consumer&.run
        end
      end

      FLOAT_REGEXP = /^[-+]?[0-9]*\.?[0-9]+$/
      def numeric?(n)
        n =~ FLOAT_REGEXP
      end
    end
  end
end
