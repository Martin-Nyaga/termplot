require "termplot/utils/ansi_safe_string"

module Termplot
  module Renderers
    class TextRenderer
      attr_reader(
        :window,
        :text,
        :row,
        :errors,
        :align
      )

      def initialize(
        bordered_window:,
        text:,
        row:,
        errors:,
        align: :center
      )

        @window = bordered_window
        @text = Termplot::Utils::AnsiSafeString.new(text)
        @row = row
        @errors = errors
        @align = align
      end

      def render
        window.cursor.row = row
        window.cursor.beginning_of_line
        window.cursor.forward(position)

        clamped_text.each do |char|
          window.write(char)
        end
      end

      private

      def clamped_text
        if (text_length + position) > (window.cols - window.border_size.right - 1)
          errors.push(
            Colors.yellow("Warning: Text has been clipped, consider using more columns with -c")
          )
          text.slice(0, window.cols - position)
        else
          text
        end
      end

      def position
        @position ||= send("position_#{align}")
      end

      def position_center
        [1, window.border_size.left + (window.inner_width - text_length + 1) / 2].max
      end

      def position_left
        0
      end

      def position_right
        [1, window.border_size.left + window.inner_width - text_length].max
      end

      def text_length
        @length ||= text.length
      end
    end
  end
end
