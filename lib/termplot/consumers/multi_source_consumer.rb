require "termplot/file_config"
require "termplot/message_broker"
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
        broker_pool.on_message { renderer_thread.continue }
        producer_thread_pool = build_producer_pool

        renderer_thread.start

        # Blocks main thread
        producer_thread_pool.start_and_block

        # Producer threads have all exited, tell renderer to consume all
        # messages left on the queue
        renderer_thread.continue while !broker_pool.empty

        # Close queues
        broker_pool.shutdown

        # Shutdown renderer
        renderer_thread.join
      end

      private

      # Parse config file
      def config
        @config ||= FileConfig.new(options).parse_config
      end

      # Build widget hierarchy and return flat array of positioned widgets
      def positioned_widgets
        @positioned_widgets ||= config.positioned_widgets
      end

      def renderer
        @renderer ||= Renderer.new(
          cols: config.cols,
          rows: config.rows,
          widgets: positioned_widgets,
          debug: options.debug
        )
      end

      def broker_pool
        @broker_pool ||= MessageBrokerPool.new
      end

        # Run renderer thread, and register it to be ran when data arrives
      def renderer_thread
        @renderer_thread ||= RendererThread.new(renderer: renderer, broker_pool: broker_pool)
      end

      def build_producer_pool
        # Build producers & register widgets to a producer
        pool = ProducerPool.new
        config.widget_configs.each do |widget_config|
          producer = Termplot::Producers::CommandProducer.new(
            widget_config.producer_options
          )
          broker_pool.broker(sender: producer, receiver: widget_config.widget)
          pool.add_producer(producer)
        end
        pool
      end

      class RendererThread
        def initialize(renderer:, broker_pool:, &block)
          @renderer = renderer
          @broker_pool = broker_pool
          @block = block
          @thread = nil
        end

        def start
          @thread = Thread.new do
            Shell.init
            # Pause and wait to be woken for rendering
            pause
            while !broker_pool.closed?
              num_samples = broker_pool.pending_message_count
              if num_samples.zero?
                pause
              else
                broker_pool.flush_messages
                if num_samples > 0
                  renderer.render
                end
              end
            end
          end
        end

        def continue
          thread.run
        end

        def pause
          Thread.stop
        end

        def join
          thread.join unless thread.stop?
        end

        private
        attr_reader :renderer, :broker_pool, :block, :thread
      end

      class ProducerPool
        def initialize
          @producers = []
          @threads = []
        end

        def start
          # Run Producers with producers
          @threads = producers.map do |producer|
            Thread.new do
              producer.run
            end
          end
        end

        def wait
          threads.each(&:join)
        end

        def start_and_block
          start
          wait
        end

        def add_producer(producer)
          producers.push(producer)
        end

        private
        attr_reader :producers, :threads
      end
    end
  end
end
