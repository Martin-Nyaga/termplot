require "termplot/cursor"

module Termplot
  class Window
    attr_reader :rows, :cols, :buffer
    def initialize(cols:, rows:)
      @rows = rows
      @cols = cols
      @buffer = Array.new(cols * rows) { Renderer::EMPTY }
    end

    def cursor
      @cursor ||= VirtualCursor.new(self)
    end

    def console_cursor
      @console_cursor ||= ConsoleCursor.new(self)
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
      size.times { write Renderer::EMPTY }
    end

    def flush
      console_cursor.reset_position

      buffer.each_slice(cols).with_index do |line, i|
        line.each do |v|
          console_cursor.write(v)
        end
        puts
      end
    end

    def flush_debug(str = "Window")
      padding = "-" * 10
      puts
      puts padding + " " + str.to_s + " " + padding
      puts
      buffer.each_slice(cols).with_index do |line, y|
        render_line = line.each_with_index.map do |c, x|
          y * cols + x == cursor.position ? "𝥺" : c
        end
        print render_line
        puts
      end
    end
  end
end
