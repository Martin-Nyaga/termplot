module Termplot
  module Utils
    class AnsiSafeString
      include Enumerable

      # Regex to match ANSI escape sequences.
      ANSI_MATCHER = Regexp.new("(\\[?\\033\\[?[;?\\d]*[\\dA-Za-z][\\];]?)")

      attr_reader :string
      def initialize(string)
        @string = string
      end

      def length
        sanitized.length
      end

      def sanitized
        string.gsub(/#{ANSI_MATCHER}/, "")
      end

      # Yield each char in the string, folding any escape sequences into the
      # next char. NOTE: If the string includes only ansi escape sequences,
      # nothing will be yielded.
      def each
        ansi_code_positions = []

        string.scan(ANSI_MATCHER) do |_|
          ansi_code_positions << Regexp.last_match.offset(0)
        end

        i = 0
        current_char = ""
        while i < string.length
          if ansi_code_positions.any? { |pos| pos[0] <= i && pos[1] > i }
            current_char << string[i]
            i += 1
          else
            current_char << string[i]

            # If the next character is a terminating ansi sequence, we need to
            # fold it into the current character, to prevent emitting an ansi
            # sequence only as the last character.
            next_char_is_terminating_ansi_sequence =
              ansi_code_positions.length > 0 &&
              ansi_code_positions.last[0] == i + 1 &&
              ansi_code_positions.last[1] == string.length

            if next_char_is_terminating_ansi_sequence
              current_char << string[i + 1..-1]
              i += 1 + (string.length - 1 - i + 1)
            else
              yield current_char
              current_char = ""
              i += 1
            end
          end
        end

        yield current_char unless current_char.empty?
      end

      def slice(start, stop)
        AnsiSafeString.new(to_a[start..stop].join)
      end
    end
  end
end
