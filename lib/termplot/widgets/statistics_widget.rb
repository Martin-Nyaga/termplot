require "termplot/window"
require "termplot/renderable"
require "termplot/window"
require "termplot/character_map"
require "termplot/widgets/border"
require "termplot/renderers"

module Termplot
  module Widgets
    class StatisticsWidget < BaseWidget
      include Termplot::Renderers::BorderRenderer
      include Termplot::Renderers::TextRenderer

      def initialize(title: "Statistics", cols:, rows:, debug: false)
        @border_size = default_border_size
        @cols = cols > min_cols ? cols : min_cols
        @rows = rows > min_rows ? rows : min_rows
        @window = Window.new(
          cols: @cols,
          rows: @rows
        )

        @debug = debug
        @errors = []

        @title = title

        @decimals = 2
        # TODO: Make max count configurable
        @max_count = 500
        @dataset = Dataset.new(max_count)
      end

      def <<(point)
        dataset << point
        dataset.set_capacity(max_count)
      end

      def render_to_window
        errors.clear
        window.clear
        window.cursor.reset_position

        render_statistics
        window.cursor.reset_position

        # Title bar
        render_aligned_text(
          window: window,
          text: title,
          row: 0,
          border_size: border_size,
          inner_width: inner_width,
          align: :right,
          errors: errors
        )
        window.cursor.reset_position

        # Borders
        render_borders(
          window: window,
          inner_width: inner_width,
          inner_height: inner_height
        )
        window.cursor.reset_position
      end

      private
      attr_reader :max_count, :decimals, :border_size


      def default_border_size
        Border.new(2, 1, 1, 1)
      end

      def min_cols
        20
      end

      def min_rows
        5 + border_size.top + border_size.bottom
      end

      def render_statistics
        titles, values = formatted_stats
        title_width = titles.map(&:length).max
        titles = titles.map { |t| t.ljust(title_width, " ") }
        lines = titles.zip(values).map do |(title, value)|
          "#{title} : #{value}"
        end
        line_width = lines.map(&:length).max
        left_padding = [0, (inner_width - line_width) / 2].max

        window.cursor.down(border_size.top)
        window.cursor.beginning_of_line
        window.cursor.forward(border_size.left + left_padding)

        lines.each do |line|
          line.chars.each do |char|
            window.write(char)
          end

          window.cursor.down
          window.cursor.beginning_of_line
          window.cursor.forward(border_size.left + left_padding)
        end
      end

      def formatted_stats
        titles = %w[Samples Min Max Mean Stdev]
        values = [:count, :min, :max, :mean, :standard_deviation].map { |stat| format_number(dataset.send(stat)) }
        [titles, values]
      end

      def format_number(n)
        "%.#{decimals}f" % n.round(decimals)
      end

      def border_char_map
        CharacterMap::DEFAULT
      end
    end
  end
end
