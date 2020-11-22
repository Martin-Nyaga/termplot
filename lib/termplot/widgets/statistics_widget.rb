# frozen_string_literal: true

require "termplot/window"
require "termplot/renderable"
require "termplot/window"
require "termplot/character_map"
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
          align: :center,
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

        window.cursor.down(border_size.top)
        window.cursor.beginning_of_line
        window.cursor.forward(border_size.left)

        title_color = "blue"
        value_color = "green"

        justified_stats = titles.zip(values).map do |(title, value)|
          field_size = [title.size, value.size].max
          title = Colors.send(title_color, title.ljust(field_size, " "))
          value = Colors.send(value_color, value.ljust(field_size, " "))
          [title, value]
        end

        col_separator = " #{border_char_map[:vert_right]} "
        stats_table = justified_stats.transpose.map { |row| row.join(col_separator) }

        start_row = inner_height > 2 ? border_size.top - 1 + inner_height / 2 : border_size.top

        stats_table.each_with_index do |row, index|
          render_aligned_text(
            window: window,
            text: row,
            row: start_row + index,
            border_size: border_size,
            inner_width: inner_width,
            errors: errors,
            align: :center
          )
        end
      end

      def formatted_stats
        titles = %w[Samples Min Max Mean Stdev]

        values = [:count, :min, :max, :mean, :standard_deviation].map do |stat|
          format_number(dataset.send(stat))
        end

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
