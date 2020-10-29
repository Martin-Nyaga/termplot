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
      @renderer = Renderer.new(cols: cols, rows: rows)
      @chart = Chart.new(max_values: renderer.inner_width)
    end

    def run
      while n = STDIN.gets&.chomp do
        chart.add_point(n.to_f)
        renderer.render(chart)
      end
    end
  end

  class Chart
    attr_reader :data, :min, :max, :range, :max_values
    def initialize(max_values:)
      @data = []
      @max_values = max_values
      @min = 0
      @max = 0
      @range = 0
    end

    def add_point(point)
      @data.push(point)

      while @data.length > max_values do
        @data.shift
      end

      @min = data.min
      @max = data.max
      @range = max - min
      @range = 1 if range.zero?
    end
  end

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

  class ConsoleCursor < VirtualCursor
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

    def up(n=1)
      moved = super(n)
      moved.times { print UP }
    end

    def down(n=1)
      moved = super(n)
      moved.times { print DOWN }
    end

    def beginning_of_line
      super
      print CR
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
      points, ticks = map_to_window(chart)
      points.each do |point|
        window.cursor.position = point.y * cols + point.x
        window.write(POINT)
      end

      window.cursor.reset_position

      # Top borders
      window.cursor.down(border_size.top - 1)
      window.cursor.forward(border_size.left - 1)
      window.write(TOP_LEFT)
      inner_width.times { window.write HORZ }
      window.write(TOP_RIGHT)
      window.cursor.forward(border_size.right - 1)

      inner_height.times do |y|
        window.cursor.forward(border_size.left - 1)
        window.write(VERT)
        window.cursor.forward(inner_width)
        window.write(VERT)
        window.cursor.forward(border_size.right - 1)
      end

      # Bottom border
      # Jump to bottom left corner
      window.cursor.down
      window.cursor.beginning_of_line
      window.cursor.forward(border_size.left - 1)
      window.write(BOT_LEFT)
      inner_width.times { window.write HORZ }
      window.write BOT_RIGHT

      # Draw axis
      window.cursor.reset_position
      window.cursor.down(border_size.top - 1)
      window.cursor.forward(border_size.left + inner_width + 1)

      ticks.each do |tick|
        window.cursor.row = tick.y
        tick.label.chars.each do |c|
          window.write(c)
        end
        window.cursor.back(label_chars)
      end

      # window.flush_debug
      window.flush
    end

    def inner_width
      cols -  border_size.left - border_size.right
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


    def inner_height
      rows - border_size.top - border_size.bottom
    end

    Border = Struct.new(:top, :right, :bottom, :left)
    def border_size
      @border_size ||= Border.new(1, 10, 1, 1)
    end

    Point = Struct.new(:x, :y, :value)
    Tick = Struct.new(:y, :label)
    def map_to_window(chart)
      points =
        chart.data.last(inner_width).map.with_index do |p, x|
          # Map from chart Y range to inner height
          y = 1 + (p.to_f - chart.min) / chart.range * (inner_height - 1)
          # Invert Y value since pixel Y is inverse of cartesian Y
          y = inner_height - y.round

          # Add padding for border width
          Point.new(x + border_size.left, y + border_size.top, p.to_f)
        end

      max_value = points.max_by(&:value).value
      min_value = points.min_by(&:value).value
      range = max_value - min_value
      tick_spacing = 1
      ticks = []
      y = border_size.top
      while y < rows - 2
        value = max_value - range / (inner_height - 1) * y
        ticks.push(Tick.new(y, format_label(value)))
        y += tick_spacing + 1
      end
      ticks.push(Tick.new(border_size.top + inner_height - 1, format_label(min_value)))

      [points, ticks]
    end

    # TODO: Better way to format labels based on available space
    def format_label(num)
      num.to_s.chars.first(label_chars).join.ljust(label_chars, " ")
    end

    def label_chars
      @label_chars ||= border_size.right - 1
    end

    def drawn?
      @drawn
    end
  end
end


