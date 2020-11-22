require "termplot/positioned_widget"
require "termplot/widgets"

module Termplot
  module DSL
    module Widgets
      def timeseries(attrs)
        attrs = merge_defaults(attrs)
        children.push(TimeSeriesConfig.new(attrs))
      end

      def statistics(attrs)
        attrs = merge_defaults(attrs)
        children.push(StatisticsConfig.new(attrs))
      end

      def histogram(attrs)
        attrs = merge_defaults(attrs)
        children.push(HistogramConfig.new(attrs))
      end

      private

      def merge_defaults(attrs)
        Termplot::Options.default_options.merge(attrs)
      end

      class WidgetConfig
        attr_reader(
          :title,
          :command,
          :interval,
          :col,
          :row,
          :cols,
          :rows,
          :debug
        )

        def initialize(opts)
          @title = opts[:title]

          @command = opts[:command]
          @interval = opts[:interval]
          @debug = opts[:debug]

          post_initialize(opts)
        end

        def post_initialize(opts)
          # Implemented in subclasses
        end

        def set_dimensions(rows, cols, start_row, start_col)
          @rows = rows
          @cols = cols
          @row = start_row
          @col = start_col
        end

        def flatten
          self
        end

        def positioned_widget
          @positioned_widget ||= PositionedWidget.new(
            row: row,
            col: col,
            widget: widget
          )
        end

        def widget
          raise "Must be implemented"
        end

        def producer_options
          ProducerOptions.new(command: command, interval: interval)
        end
      end

      class TimeSeriesConfig < WidgetConfig
        attr_reader :color, :line_style
        def post_initialize(opts)
          @color = opts[:color]
          @line_style = opts[:line_style]
        end

        def widget
          @widget ||= Termplot::Widgets::TimeSeriesWidget.new(
            title: title,
            line_style: line_style,
            color: color,
            cols: cols,
            rows: rows,
            debug: debug
          )
        end
      end

      class StatisticsConfig < WidgetConfig
        def widget
          @widget ||= Termplot::Widgets::StatisticsWidget.new(
            title: title,
            cols: cols,
            rows: rows,
            debug: debug
          )
        end
      end

      class HistogramConfig < WidgetConfig
        attr_reader :color
        def post_initialize(opts)
          @color = opts[:color]
        end

        def widget
          @widget ||= Termplot::Widgets::HistogramWidget.new(
            title: title,
            cols: cols,
            rows: rows,
            debug: debug
          )
        end
      end
    end
  end
end
