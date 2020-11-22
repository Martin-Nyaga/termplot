# frozen_string_literal: true

require "termplot/widgets/border"
require "termplot/widgets/dataset"

module Termplot
  module Widgets
    class BaseWidget
      include Renderable

      attr_reader :window, :errors

      def <<(point)
        dataset << point
        dataset.set_capacity(max_count)
      end

      def render_to_window
        raise "Must be implemented"
      end

      private
      attr_reader(
        :cols,
        :rows,
        :dataset,
        :title,
        :max_count,
        :bordered_window
      )

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
