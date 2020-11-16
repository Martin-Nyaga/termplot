module Termplot
  module Renderers
    module TextRenderer
      # Regex to match ANSI codes.
      ANSI_MATCHER = Regexp.new("(\\[?\\033\\[?[;?\\d]*[\\dA-Za-z][\\];]?)")

      # Renders aligned text at a given row in a window
      def render_aligned_text(
        window:,
        text:,
        row:,
        border_size:,
        inner_width:,
        errors:,
        align: :center
      )
        position = 0
        sanitized_length = sanitize_ansi(text).length
        if align == :center
          position = [
            1,
            (border_size.left + inner_width - sanitized_length) / 2
          ].max
        elsif align == :right
          sanitized_length = sanitize_ansi(text).length
          position = [1, border_size.left + inner_width - sanitized_length].max
        end


        if (sanitized_length + position) > cols
          errors.push(
            Colors.yellow("Warning: Text has been clipped, consider using more columns with -c")
          )

          text = text[0..(cols - position)]
        end

        window.cursor.row = row
        window.cursor.forward(position)

        each_char_including_ansi(text) do |char|
          window.write(char)
        end
      end

      private
      def sanitize_ansi(text)
        text.gsub(/#{ANSI_MATCHER}/, "")
      end

      # Yield each char in a string, folding any escape sequences into the next
      # char. NOTE: If the string includes only ansi escape sequences, nothing
      # will be yielded.
      def each_char_including_ansi(string)
        ansi_code_positions = []

        string.scan(ANSI_MATCHER) do |_|
          ansi_code_positions << Regexp.last_match.offset(0)
        end

        i = 0
        current_char = ""
        while i < string.length
          if ansi_code_positions.any? { |pos| pos[0] <= i && pos[1] > i }
            current_char << string[i]
          else
            current_char << string[i]
            yield current_char
            current_char = ""
          end

          i += 1
        end

        yield current_char unless current_char.empty?
      end
    end
  end
end
