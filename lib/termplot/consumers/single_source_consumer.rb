
require "termplot/positioned_widget"
require "termplot/widgets"
require "termplot/producers"

module Termplot
  module Consumers
    class SingleSourceConsumer < BaseConsumer
      def positioned_widgets
        @positioned_widgets ||= [PositionedWidget.new(row: 0, col: 0, widget: widget)]
      end

      def register_producers_and_brokers
        producer = build_producer
        broker_pool.broker(sender: producer, receiver: widget)
        producer_pool.add_producer(producer)
      end

      private
      def widget
        @widget ||= Termplot::Widgets::TimeSeriesWidget.new(
          title: options.title,
          line_style: options.line_style,
          color: options.color,
          cols: options.cols,
          rows: options.rows,
          debug: options.debug
        )
      end

      def build_producer
        producer_class.new(options.producer_options)
      end
    end
  end
end
