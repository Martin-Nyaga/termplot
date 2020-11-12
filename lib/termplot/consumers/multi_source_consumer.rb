module Termplot
  module Consumers
    class MultiSourceConsumer
      attr_reader :options

      def initialize(options)
        @options = options
      end

      def run
        # Parse file into dashboard configuration

        # Build widget hierarchy & initialize renderer

        # Build producers & register widgets to a producer
        # TODO: Need a better abstraction to register a widget with a source

        # Run renderer thread

        # Run ProducerPool with producers
      end
    end
  end
end
