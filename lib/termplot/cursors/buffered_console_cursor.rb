module Termplot
  module Cursors
    class BufferedConsoleCursor < VirtualCursor
      include Termplot::ControlChars
      attr_reader :buffer

      def initialize(window, buffer)
        super(window)
        @buffer = buffer
      end

      def write(char)
        if writeable?
          buffer << char
          super(char)
        end
      end

      def forward(n = 1)
        moved = super(n)
        moved.times { buffer << FORWARD }
      end

      def back(n = 1)
        moved = super(n)
        moved.times { buffer << BACK }
      end

      def up(n=1)
        moved = super(n)
        moved.times { buffer << UP }
      end

      def down(n=1)
        moved = super(n)
        moved.times { buffer << DOWN }
      end

      def beginning_of_line
        super
        buffer << CR
      end

      def new_line
        buffer << NEWLINE
      end

      def clear_buffer
        buffer.clear
      end

      def flush
        print buffer.join
      end

      def position=()
        raise "Cannot set cursor position directly"
      end

      def row=()
        raise "Cannot set cursor position directly"
      end

      def col=()
        raise "Cannot set cursor position directly"
      end
    end
  end
end
