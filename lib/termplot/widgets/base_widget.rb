# frozen_string_literal: true

require "termplot/widgets/border"
require "termplot/widgets/dataset"

module Termplot
  module Widgets
    class BaseWidget
      include Renderable

      attr_reader(
        :cols,
        :rows,
        :window,
        :bordered_window,
        :errors,
        :title,
        :decimals,
        :dataset
      )

      def initialize(**opts)
        @cols = opts[:cols] >= min_cols ? opts[:cols] : min_cols
        @rows = opts[:rows] >= min_rows ? opts[:rows] : min_rows
        @window = Window.new(
          cols: @cols,
          rows: @rows
        )

        @bordered_window = BorderedWindow.new(window, default_border_size)
        @debug = opts[:debug]
        @errors = []

        @title = opts[:title]
        @decimals = 2

        @dataset = Dataset.new(max_count)

        post_initialize(opts)
      end

      def post_initialize(opts)
        # Implemented by subclasses
      end

      def <<(point)
        dataset << point
        dataset.set_capacity(max_count)
      end

      def render_to_window
        raise "Must be implemented"
      end

      private
      def max_count
        10_000
      end

      BorderedWindow = Struct.new(:window, :border_size) do
        def inner_width
          window.cols - border_size.left - border_size.right
        end

        def inner_height
          window.rows - border_size.top - border_size.bottom
        end

        def method_missing(method, *args, &block)
          if window.respond_to?(method)
            window.send(method, *args, &block)
          else
            super
          end
        end
      end
    end
  end
end
