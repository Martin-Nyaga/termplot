require "termplot/utils/ansi_safe_string"
module Termplot
  module Renderers
    class TextRenderer
      attr_reader(
        :window,
        :text,
        :row,
        :cols,
        :border_size,
        :inner_width,
        :errors,
        :align
      )

      def initialize(
        window:,
        text:,
        row:,
        cols:,
        border_size:,
        inner_width:,
        errors:,
        align: :center
      )
        @window      = window
        @text        = text
        @row         = row
        @cols        = cols
        @border_size = border_size
        @inner_width = inner_width
        @errors      = errors
        @align       = align
      end

      # Renders aligned text at a given row in a window
      def render
        position = 0
        ansi_safe_text = Termplot::Utils::AnsiSafeString.new(text)
        sanitized_length = ansi_safe_text.length
        if align == :center
          position = [
            1,
            border_size.left + (inner_width - sanitized_length + 1) / 2
          ].max
        elsif align == :right
          sanitized_length = sanitize_ansi(text).length
          position = [1, border_size.left + inner_width - sanitized_length].max
        end


        if (sanitized_length + position) > (cols - border_size.right - 1)
          errors.push(
            Colors.yellow("Warning: Text has been clipped, consider using more columns with -c")
          )

          ansi_safe_text = ansi_safe_text.slice(0, cols - position)
        end

        window.cursor.row = row
        window.cursor.beginning_of_line
        window.cursor.forward(position)

        ansi_safe_text.each do |char|
          window.write(char)
        end
      end
    end
  end
end