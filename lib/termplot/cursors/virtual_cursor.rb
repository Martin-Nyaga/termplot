module Termplot
  module Cursors
    class VirtualCursor
      attr_reader :position, :window

      def initialize(window)
        @window = window
        @position = 0
      end

      def write(char)
        @position += 1 if writeable?
      end

      def writeable?
        position < window.buffer.size
      end

      def forward(n = 1)
        movable_chars = window.buffer.size - position
        chars_to_move = [movable_chars, n].min
        @position += chars_to_move
        chars_to_move
      end

      def back(n = 1)
        chars_to_move = [position, n].min
        @position -= chars_to_move
        chars_to_move
      end

      def up(n=1)
        return unless row > 0
        rows_to_move = [n, row].min
        @position -= rows_to_move * window.cols
        rows_to_move
      end

      def row
        (position / window.cols).floor
      end

      def col
        position % window.cols
      end

      def row=(y)
        @position = y * window.cols + col
      end

      def col=(x)
        beginning_of_line
        forward(x)
      end

      def down(n=1)
        return 0 unless row < (window.rows - 1)
        rows_to_move = [n, window.rows - 1 - row].min
        @position += window.cols * rows_to_move
        rows_to_move
      end

      def beginning_of_line
        @position = position - (position % window.cols)
      end

      def position=(n)
        @position = n
      end

      def reset_position
        return if position == 0
        up(row) # Go up by row num times
        beginning_of_line
      end
    end
  end
end
