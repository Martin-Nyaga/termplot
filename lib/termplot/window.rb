require "termplot/control_chars"
require "termplot/cursors"

module Termplot
  class Window
    attr_reader :rows, :cols, :buffer
    def initialize(cols:, rows:)
      @rows = rows
      @cols = cols
      @buffer = Array.new(cols * rows) { CharacterMap::DEFAULT[:empty] }
    end

    def cursor
      @cursor ||= Termplot::Cursors::VirtualCursor.new(self)
    end

    def console_cursor
      # Console buffer has an extra rows - 1 to account for new line characters
      # between rows
      @console_cursor ||=
        Termplot::Cursors::BufferedConsoleCursor.new(self, Array.new(cols * rows + rows - 1))
    end

    def size
      rows * cols
    end

    def write(char)
      buffer[cursor.position] = char
      cursor.write(char)
    end

    def clear
      cursor.reset_position
      size.times { write CharacterMap::DEFAULT[:empty] }
    end

    # Flush rendered window to a string
    def flush
      console_cursor.clear_buffer
      console_cursor.reset_position
      buffer.each_slice(cols).with_index do |line, i|
        line.each do |v|
          console_cursor.write(v)
        end
        console_cursor.new_line
      end
      console_cursor.flush
    end

    # Flush to 2d array rather than string
    def flush_debug
      debug_arr = []
      buffer.each_slice(cols).with_index do |line, y|
        render_line = line.each_with_index.map do |c, x|
          y * cols + x == cursor.position ? "𝥺" : c
        end
        debug_arr << render_line
        debug_arr << "\n"
      end
      debug_arr
    end

    # TODO: Refine later and include errors properly in the window
    def print_errors(errors)
      print errors.join(Termplot::ControlChars::NEWLINE)
      print Termplot::ControlChars::NEWLINE
      errors.length.times { print Termplot::ControlChars::UP }
    end

    def blit(other, start_row, start_col)
      cursor.position = start_row * cols + start_col

      other.each_row do |row|
        row.each do |char|
          write(char)
        end
        cursor.down unless cursor.beginning_of_line?
        cursor.col = start_col
      end
    end

    def each_row
      buffer.each_slice(cols) do |row|
        yield row
      end
    end
  end
end
