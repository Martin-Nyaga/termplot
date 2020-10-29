require "termplot/version"
require "optparse"
require "termios"

module Termplot
  class Error < StandardError; end

  class CLI
    def self.run
      opts = self.parse_options
      Consumer.new(**opts).run
    end

    private
      def self.parse_options
        options = { rows: 20, cols: 80 }
        OptionParser.new do |opts|
          opts.on("-rROWS", "--rows=ROWS", "rows") do |v|
            options[:rows] = v.to_i
          end

          opts.on("-cCOLS", "--cols=COLS", "cols") do |v|
            options[:cols] = v.to_i
          end
        end.parse!
        options
      end
  end

  class Consumer
    attr_reader :chart, :renderer

    def initialize(cols:, rows:)
      @chart = Chart.new
      @renderer = Renderer.new(cols: cols, rows: rows)
    end

    def run
      while n = STDIN.gets&.chomp do
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
      chars_to_move = [movable_chars, n].min
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

  class VirtualCursor < Cursor
    def position=(n)
      @position = n
    end
  end

  class ConsoleCursor < Cursor
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

  # TODO: No need for virtual cursor really, only need to keep track of the real
  # cursor. This would also provide a cleaner API for writing data to the window
  class Window
    attr_reader :rows, :cols, :buffer, :cursor, :console_cursor
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

    def advance_cursor(n=1)
      cursor.forward(n)
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
      console_cursor.reset_position

      buffer.each_slice(cols).with_index do |line, i|
        line.each do |v|
          console_cursor.write(v)
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

      init_shell
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
      window.advance_cursor(border_size.left - 1)
      window.write(TOP_LEFT)
      inner_width.times { window.write HORZ }
      window.write(TOP_RIGHT)

      inner_height.times do |y|
        y += 1
        window.set_cursor(y * cols)
        window.advance_cursor(border_size.left - 1)
        window.write(VERT)
        window.advance_cursor(inner_width)
        window.write(VERT)
      end

      # Bottom border
      # Jump to bottom left corner
      window.set_cursor((rows - 1) * cols)
      window.advance_cursor(border_size.left - 1)
      window.write(BOT_LEFT)
      inner_width.times { window.write HORZ }
      window.write BOT_RIGHT

      window.flush_debug
      # window.flush
    end

    private
    attr_reader :termios_settings

    CURSOR_HIDE = "\e[?25l"
    CURSOR_SHOW = "\e[?25h"
    def init_shell
      # Disable echo on stdout tty, prevents printing chars if you type in
      # between rendering
      @termios_settings = Termios.tcgetattr($stdout)
      new_termios_settings = termios_settings.dup
      new_termios_settings.c_lflag &= ~(Termios::ECHO)
      Termios.tcsetattr($stdout, Termios::TCSAFLUSH, new_termios_settings)

      print CURSOR_HIDE
      at_exit { reset_shell }
      Signal.trap("INT") { exit(0) }
    end

    def reset_shell
      # Reset stdout tty to original settings
      Termios.tcsetattr($stdout, Termios::TCSAFLUSH, termios_settings)

      print CURSOR_SHOW
    end

    def inner_width
      cols -  border_size.left - border_size.right
    end

    def inner_height
      rows - border_size.top - border_size.bottom
    end

    Border = Struct.new(:top, :right, :bottom, :left)
    def border_size
      @border_size ||= Border.new(1, 5, 1, 2)
    end

    Point = Struct.new(:x, :y)
    def map_to_window(chart)
      chart.data.last(inner_width).map.with_index do |p, x|
        # Map from chart Y range to inner height
        y = 1 + (p.to_f - chart.min) / chart.range * (inner_height - 1)
        # Invert Y value since pixel Y is inverse of cartesian Y
        y = inner_height - y.round

        # Add padding for border width
        Point.new(x + border_size.left, y + border_size.top)
      end
    end

    def drawn?
      @drawn
    end
  end
end


