require "forwardable"

require "termplot/renderer"
require "termplot/shell"
require "termplot/widgets"
require "termplot/producers"

module Termplot
  module Consumers
    class StdinConsumer
      attr_reader :options, :widget, :renderer

      def initialize(options)
        @options = options
        @widget = Termplot::Widgets::TimeSeriesWidget.new(
          title: options.title,
          line_style: options.line_style,
          color: options.color,
          cols: options.cols,
          rows: options.rows,
          debug: options.debug
        )
        @renderer = Renderer.new(
          cols: options.cols,
          rows: options.rows,
          widgets: [
            PositionedWidget.new(row: 0, col: 0, widget: widget),
          ],
          debug: options.debug
        )
      end

      def run
        Shell.init

        queue = Queue.new

        # The broker pool will broker messages from one or more queues and ensure
        # they are delivered to one or more destinations (in this case, a widget)
        broker_pool = BrokerPool.new
        broker_pool.broker_messages(queue, widget)

        # Consumer thread will process and render any available input in the
        # broker_pool's queues. If no samples are available but some queue is
        # still open, the thread will sleep until woken to render new input.
        consumer_thread = Thread.new do
          while !broker_pool.closed?
            num_samples = broker_pool.pending_message_count
            if num_samples.zero?
              Thread.stop
            else
              broker_pool.flush_messages
              renderer.render
            end
          end
        end

        # Producer will run in the main thread and will block while producing
        # samples from some source (which depends on the type of producer).
        # Each value is added to the queue and the consumer will be woken to
        # check the queue
        producer = build_producer
        producer.on_message do |value|
          queue << value
          consumer_thread.run
        end
        producer.run

        # As soon as producer continues, and we first give the consumer a chance
        # to finish rendering the queue, then close the queue.
        while !broker_pool.empty? do
          consumer_thread.run
        end
        queue.close
        consumer_thread.join unless consumer_thread.stop?
      end

      private

      PositionedWidget = Struct.new(:row, :col, :widget, keyword_init: true) do
        extend Forwardable
        def_delegators :widget, :window, :errors, :render_to_window
      end

      def build_producer
        producer_class = {
          command: "Termplot::Producers::CommandProducer",
          stdin: "Termplot::Producers::StdinProducer"
        }.fetch(options.mode)
        Object.const_get(producer_class).new(options)
      end

      class BrokerPool
        def initialize
          @brokers = []
        end

        def broker_messages(queue, reader)
          @brokers.push(Broker.new(queue, reader))
        end

        def closed?
          brokers.all?(:closed?)
        end

        def flush_messages
          brokers.each(&:flush_queue)
        end

        def pending_message_count
          brokers.inject(0) do |sum, broker|
            sum + broker.pending_message_count
          end
        end

        def empty?
          pending_message_count == 0
        end

        private
        attr_reader :brokers

        Broker = Struct.new(:queue, :reader) do
          extend Forwardable
          def_delegators :queue, :closed

          def flush_queue
            num_samples = queue.size
            num_samples.times do
              reader << queue.shift
            end
          end

          def pending_message_count
            queue.size
          end
        end
      end

    end
  end
end
