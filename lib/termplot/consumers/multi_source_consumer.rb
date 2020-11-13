require "termplot/file_config"
require "termplot/broker_pool"
require "termplot/shell"
require "termplot/renderer"
require "termplot/producers"

module Termplot
  module Consumers
    class MultiSourceConsumer
      attr_reader :options

      def initialize(options)
        @options = options
      end

      def run
        # Parse config file
        config = FileConfig.new(options).parse_config

        # Build widget hierarchy & initialize renderer
        positioned_widgets = config.positioned_widgets
        renderer = Renderer.new(
          cols: config.cols,
          rows: config.rows,
          widgets: positioned_widgets,
          debug: options.debug
        )

        broker_pool = BrokerPool.new
        Shell.init

        # Run renderer thread
        consumer_thread = Thread.new do
          while !broker_pool.closed?
            num_samples = broker_pool.pending_message_count
            if num_samples.zero?
              Thread.stop
            else
              broker_pool.flush_messages
              if num_samples > 0
                renderer.render
              end
            end
          end
        end

        # Build producers & register widgets to a producer
        producers = config.widget_configs.map do |widget_config|
          producer = Termplot::Producers::CommandProducer.new(
            widget_config.producer_options
          )

          queue = Queue.new
          producer.on_message do |value|
            queue << value
            consumer_thread.run
          end

          broker_pool.broker_messages(queue, widget_config.widget)
          producer
        end

        # Run Producers with producers
        producer_threads = producers.map do |producer|
          Thread.new do
            producer.run
          end
        end

        producer_threads.each(&:join)

        while !broker_pool.empty? do
          consumer_thread.run
        end
        broker_pool.close_all_queues
        consumer_thread.join unless consumer_thread.stop?
      end
    end
  end
end
