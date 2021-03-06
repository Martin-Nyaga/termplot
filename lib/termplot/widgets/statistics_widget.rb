# frozen_string_literal: true

require "termplot/window"
require "termplot/renderable"
require "termplot/window"
require "termplot/character_map"
require "termplot/renderers"

module Termplot
  module Widgets
    class StatisticsWidget < BaseWidget
      def render_to_window
        errors.clear
        window.clear
        window.cursor.reset_position

        render_statistics
        window.cursor.reset_position

        # Title bar
        Termplot::Renderers::TextRenderer.new(
          bordered_window: bordered_window,
          text: title,
          row: 0,
          align: :center,
          errors: errors
        ).render

        window.cursor.reset_position

        # Borders
        Termplot::Renderers::BorderRenderer.new(
          bordered_window: bordered_window
        ).render

        window.cursor.reset_position
      end

      private
      def default_border_size
        Border.new(2, 1, 1, 1)
      end

      def min_cols
        20
      end

      def min_rows
        5 + default_border_size.top + default_border_size.bottom
      end

      def render_statistics
        titles, values = formatted_stats

        window.cursor.down(bordered_window.border_size.top)
        window.cursor.beginning_of_line
        window.cursor.forward(bordered_window.border_size.left)

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

        start_row = bordered_window.inner_height > 2 ? bordered_window.border_size.top - 1 + bordered_window.inner_height / 2 : bordered_window.border_size.top

        stats_table.each_with_index do |row, index|
          Termplot::Renderers::TextRenderer.new(
            bordered_window: bordered_window,
            text: row,
            row: start_row + index,
            errors: errors,
            align: :center
          ).render
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
