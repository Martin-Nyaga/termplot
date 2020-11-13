require "yaml"

require "termplot/positioned_widget"
require "termplot/widgets"

module Termplot
  class FileConfig
    attr_reader :rows, :cols, :widget_configs
    def initialize(options)
      @path = options.file
      @rows = options.rows
      @cols = options.cols
      @widget_configs = nil
    end

    # TODO: Forward debug to widgets?
    def parse_config
      code = File.read(path)
      top_level_panel = Col.new
      top_level_panel.instance_eval(code)

      @widget_configs = resolve_widget_positions(top_level_panel)
      self
    end

    def positioned_widgets
      widget_configs.map(&:positioned_widget)
    end

    private
    attr_reader :path

    def resolve_widget_positions(top_level_panel)
      top_level_panel.set_dimensions(rows, cols, 0, 0)
      top_level_panel.flatten
    end

    class Panel
      attr_accessor :rows,
                    :cols,
                    :start_row,
                    :start_col

      def initialize(children = [])
        @children = children
      end

      def set_dimensions(rows, cols, start_row, start_col)
        raise "Must be implemented"
      end

      def flatten
        children.map(&:flatten).flatten
      end

      private
      attr_reader :children

      def row(&block)
        new_row = Row.new
        new_row.instance_eval(&block)
        children.push new_row
      end

      def col(&block)
        new_col = Col.new
        new_col.instance_eval(&block)
        children.push new_col
      end

      def timeseries(attrs)
        children.push TimeSeriesConfig.new(**attrs)
      end
    end

    class Row < Panel
      def set_dimensions(rows, cols, start_row, start_col)
        @rows = rows
        @cols = cols
        child_cols = cols / children.count
        children.each_with_index do |child, index|
          child.set_dimensions(
            rows,
            child_cols,
            start_row,
            child_cols * index
          )
        end
      end
    end

    class Col < Panel
      def set_dimensions(rows, cols, start_row, start_col)
        @rows = rows
        @cols = cols
        child_rows = rows / children.count
        children.each_with_index do |child, index|
          child.set_dimensions(
            child_rows,
            cols,
            child_rows * index,
            start_col
          )
        end
      end
    end

    class WidgetConfig
      attr_reader :title,
                  :color,
                  :line_style,
                  :command,
                  :interval,
                  :col,
                  :row,
                  :cols,
                  :rows,
                  :debug

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
        raise "Must be implemented"
      end

      def widget
        raise "Must be implemented"
      end

      def producer_options
        ProducerOptions.new(command: command, interval: interval)
      end
    end

    class TimeSeriesConfig < WidgetConfig
      def initialize(
        title: nil,
        color: nil,
        line_style: nil,
        command: nil,
        interval: 1000
      )
        @title = title
        @color = color
        @line_style = line_style

        @command = command
        @interval = interval
      end

      def positioned_widget
        @positioned_widget ||= PositionedWidget.new(
          row: row,
          col: col,
          widget: widget
        )
      end

      def widget
        @widget ||= Termplot::Widgets::TimeSeriesWidget.new(
          # TODO: Collapse defaults somewhere
          title: title || "Series",
          line_style: line_style || "line",
          color: color || "red",
          cols: cols,
          rows: rows
          # TODO: Need to pass debug
          # debug: options.debug
        )
      end
    end
  end
end
