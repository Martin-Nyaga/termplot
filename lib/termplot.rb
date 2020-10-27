require "termplot/version"

module Termplot
  class Error < StandardError; end
  # Your code goes here...

  class Consumer
    attr_reader :chart, :renderer

    def initialize
      @chart = Chart.new
      @renderer = Renderer.new
    end

    def self.run
      new.run
    end

    def run
      while n = gets&.chomp do
        chart.add_point(n.to_f)
        renderer.render(chart)
      end

    end
  end

  class Chart
    attr_reader :data, :min, :max, :range
    def initialize
      @data = []
      @min = 0
      @max = 0
      @range = 0
    end

    def add_point(point)
      @data.push(point)

      @min = point < min ? point : min
      @max = point > max ? point : max
      @range = max - min
    end
  end

  class Cursor
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
      chars_to_move = [movable, n].min
      @position += chars_to_move
      chars_to_move
    end

    def back(n = 1)
      chars_to_move = [position, n].min
      @position -= chars_to_move
      chars_to_move
    end

    def up
      if row > 0
        @position -= window.cols
        1
      else
        0
      end
    end

    def row
      (position / window.cols).floor
    end

    def down
      if row < (window.rows - 1)
        @position += window.cols
        1
      else
        0
      end
    end

    def beginning_of_line
      @position = (position / window.cols).floor
    end

    def position=()
      raise "Cannot set cursor position directly"
    end

    def reset_position
      return if position == 0
      while row > 0 do
        up
      end
      beginning_of_line
    end
  end

  class FakeCursor < Cursor
    def position=(n)
      @position = n
    end
  end

  class RealCursor < Cursor
    CR = "\r"
    UP = "\e[A"
    DOWN = "\e[B"
    FORWARD = "\e\[C"
    BACK = "\e\[D"

    def write(char)
      if writeable?
        print(char)
        super(char)
      end
    end

    def forward(n = 1)
      moved = super(n)
      moved.times { print FORWARD }
    end

    def back(n = 1)
      moved = super(n)
      moved.times { print BACK }
    end

    def up
      moved = super
      moved.times { print UP }
    end

    def down
      moved = super
      moved.times { print DOWN }
    end

    def beginning_of_line
      super
      print CR
    end
  end

  class Window
    attr_reader :rows, :cols, :buffer, :cursor, :real_cursor
    def initialize(cols:, rows:)
      @rows = rows
      @cols = cols
      @buffer = Array.new(cols * rows) { Renderer::EMPTY }
    end

    def cursor
      @cursor ||= FakeCursor.new(self)
    end

    def real_cursor
      @real_cursor ||= RealCursor.new(self)
    end

    def size
      rows * cols
    end

    def write(char)
      buffer[cursor.position] = char
      cursor.write(char)
    end

    def advance
      cursor.next
    end

    def reset_cursor
      cursor.reset_position
    end

    def set_cursor(position)
      cursor.position = position
    end

    def clear
      reset_cursor
      size.times { write Renderer::EMPTY }
    end

    def flush
      real_cursor.reset_position

      buffer.each_slice(cols).with_index do |line, i|
        line.each do |v|
          real_cursor.write(v)
        end
        puts
      end
    end

    def flush_debug
      puts
      puts "----"
      puts
      buffer.each_slice(cols) do |line|
        print line
        puts
      end
    end
  end


  class Renderer
    attr_reader :cols, :rows, :window

    EMPTY = " "
    POINT = "•"
    VERT = "│"
    HORZ = "─"
    BOT_LEFT = "└"
    TOP_RIGHT = "┐"
    TOP_LEFT = "┌"
    BOT_RIGHT = "┘"

    def initialize(cols: 80, rows: 20)
      @cols = cols
      @rows = rows
      @window = Window.new(cols: cols, rows: rows)
      @drawn = false
    end

    def render(chart)
      window.clear

      # Map to window coordinates and render to buffer
      points = map_to_window(chart)
      points.each_with_index do |point, x|
        window.set_cursor(point.y * cols + point.x)
        window.write(POINT)
      end

      window.reset_cursor
      # Top borders
      window.write(TOP_LEFT)
      inner_width.times { window.write HORZ }
      window.write(TOP_RIGHT)

      inner_height.times do |y|
        y += 1
        window.set_cursor(y * cols)
        window.write(VERT)
        window.set_cursor(y * cols + (cols - 1))
        window.write(VERT)
      end

      # Bottom border
      window.write(BOT_LEFT)
      inner_width.times { window.write HORZ }
      window.write BOT_RIGHT

      window.flush
    end

    private

    def inner_width
      cols - 2 * border_width
    end

    def inner_height
      rows - 2 * border_width
    end

    def border_width
      1
    end

    Point = Struct.new(:x, :y)
    def map_to_window(chart)
      chart.data.last(inner_width).map.with_index do |p, x|
        # Map from chart Y range to inner height
        y = 1 + (p.to_f - chart.min) / chart.range * (inner_height - 1)
        # Invert Y value since pixel Y is inverse of cartesian Y
        y = inner_height - y.round

        # Add padding for border width
        Point.new(x + border_width, y + border_width)
      end
    end

    def jump_to_start
    end

    def drawn?
      @drawn
    end
  end
end


