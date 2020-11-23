require "termplot/renderer"
require "termplot/message_broker"
require "termplot/shell"

module Termplot
  module Consumers
    class BaseConsumer
      def initialize(options)
        @options = options
        @broker_pool = MessageBrokerPool.new
        @producer_pool = ProducerPool.new
        @renderer = Renderer.new(
          cols: options.cols,
          rows: options.rows,
          widgets: positioned_widgets,
          debug: options.debug
        )

        @renderer_thread = RendererThread.new(
          renderer: renderer,
          broker_pool: broker_pool
        )
      end

      def run
        register_producers_and_brokers
        broker_pool.on_message { renderer_thread.continue }

        Shell.init(clear: options.full_screen)
        renderer_thread.start

        # Blocks main thread
        producer_pool.start_and_block

        # At this point producer threads have all exited, tell renderer to
        # consume all messages left on the queue
        renderer_thread.continue while !broker_pool.empty?

        # Close queues
        broker_pool.shutdown

        # Shutdown renderer
        renderer_thread.join
      end

      private
      attr_reader :options,
                  :broker_pool,
                  :producer_pool,
                  :renderer,
                  :renderer_thread

      class RendererThread
        def initialize(renderer:, broker_pool:, &block)
          @renderer = renderer
          @broker_pool = broker_pool
          @block = block
          @thread = nil
        end

        def start
          @thread = Thread.new do
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
