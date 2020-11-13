require "termplot/renderer"
require "termplot/shell"
require "termplot/positioned_widget"
require "termplot/widgets"
require "termplot/producers"
require "termplot/broker_pool"

module Termplot
  module Consumers
    class StdinConsumer
      attr_reader :options

      def initialize(options)
        @options = options
      end

      def run
        widget = Termplot::Widgets::TimeSeriesWidget.new(
          title: options.title,
          line_style: options.line_style,
          color: options.color,
          cols: options.cols,
          rows: options.rows,
          debug: options.debug
        )
        renderer = Renderer.new(
          cols: options.cols,
          rows: options.rows,
          widgets: [
            PositionedWidget.new(row: 0, col: 0, widget: widget),
          ],
          debug: options.debug
        )

        queue = Queue.new

        # The broker pool will broker messages from one or more queues and ensure
        # they are delivered to one or more destinations (in this case, a widget)
        broker_pool = BrokerPool.new
        broker_pool.broker_messages(queue, widget)

        # Consumer thread will process and render any available input in the
        # broker_pool's queues. If no samples are available but some queue is
        # still open, the thread will sleep until woken to render new input.
        Shell.init
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
        broker_pool.close_all_queues
        consumer_thread.join unless consumer_thread.stop?
      end

      private

      def build_producer
        producer_class = {
          command: "Termplot::Producers::CommandProducer",
          stdin: "Termplot::Producers::StdinProducer"
        }.fetch(options.mode)
        Object.const_get(producer_class).new(options.producer_options)
      end
    end
  end
end
