require "termplot/window"
require "termplot/renderable"
require "termplot/window"
require "termplot/character_map"

module Termplot
  module Widgets
    class StatisticsWidget < BaseWidget
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
        @dataset = Termplot::Widgets::Dataset.new(max_count)
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
        render_title
        window.cursor.reset_position

        # Borders
        render_borders
        window.cursor.reset_position
      end

      private
      attr_reader :max_count, :decimals, :border_size

      def inner_width
        cols - border_size.left - border_size.right
      end

      def inner_height
        rows - border_size.top - border_size.bottom
      end

      def default_border_size
        Termplot::Widgets::Border.new(2, 1, 1, 1)
      end

      def min_cols
        20
      end

      def min_rows
        5 + border_size.top + border_size.bottom
      end

      def render_statistics
        window.cursor.down(border_size.top)
        window.cursor.beginning_of_line
        window.cursor.forward(border_size.left)

        formatted_stats.each do |stat|
          stat.chars.each do |char|
            window.write(char)
          end

          window.cursor.down
          window.cursor.beginning_of_line
          window.cursor.forward(border_size.left)
        end
      end

      def formatted_stats
        [
          "Count: #{format_number(dataset.count)}",
          "Min: #{format_number(dataset.min)}",
          "Max: #{format_number(dataset.max)}",
          "Mean: #{format_number(dataset.mean)}",
          "Stdev: #{format_number(dataset.standard_deviation)}"
        ]
      end

      def format_number(n)
        "%.#{decimals}f" % n.round(decimals)
      end

      def render_title
        title_to_render = title

        legend_position = [1, (border_size.left + 1 + inner_width) / 2 - (title_to_render.length + 2) / 2].max

        if (title_to_render.length + legend_position) > cols
          errors.push(Colors.yellow("Warning: Title has been clipped, consider using more rows with -r"))
          title_to_render = title_to_render[0..(cols - legend_position - 2)]
        end

        window.cursor.forward(legend_position)

        title_to_render.chars.each do |char|
          window.write(char)
        end
      end

      def render_borders
        window.cursor.down(border_size.top - 1)
        window.cursor.forward(border_size.left - 1)
        window.write(border_char_map[:top_left])
        inner_width.times { window.write(border_char_map[:horz_top]) }
        window.write(border_char_map[:top_right])
        window.cursor.forward(border_size.right - 1)

        inner_height.times do |y|
          window.cursor.forward(border_size.left - 1)
          window.write(border_char_map[:vert_right])
          window.cursor.forward(inner_width)
          window.write(border_char_map[:vert_left])
          window.cursor.forward(border_size.right - 1)
        end

        # Bottom border
        # Jump to bottom left corner
        window.cursor.forward(border_size.left - 1)
        window.write(border_char_map[:bot_left])
        inner_width.times { window.write(border_char_map[:horz_top]) }
        window.write(border_char_map[:bot_right])
      end

      def border_char_map
        CharacterMap::DEFAULT
      end
    end
  end
end
