# frozen_string_literal: true

require "termplot/window"
require "termplot/character_map"
require "termplot/colors"

module Termplot
  class Renderer
    attr_reader :cols, :rows

    def initialize(cols: 80, rows: 20, debug: false)
      # Default border size, right border allocation will change dynamically as
      # data comes in to account for the length of the numbers to be printed in
      # the axis ticks
      @border_size = default_border_size
      @cols = cols > min_cols ? cols : min_cols
      @rows = rows > min_rows ? rows : min_rows
      @window = Window.new(cols: @cols, rows: @rows)
      @decimals = 2
      @tick_spacing = 3
      @debug = debug
      @errors = []
    end

    def render(series)
      window.clear
      errors.clear

      # Calculate width of right hand axis
      calculate_axis_size(series)

      # Points
      points = build_points(series)
      render_points(series, points)
      window.cursor.reset_position

      # Title bar
      render_title(series)
      window.cursor.reset_position

      # Borders
      render_borders
      window.cursor.reset_position

      # Draw axis
      ticks = build_ticks(points)
      render_axis(ticks)

      # Flush window to screen
      debug? ?
        window.flush_debug :
        window.flush

      if errors.any?
        window.print_errors(errors)
      end
    end

    def inner_width
      cols -  border_size.left - border_size.right
    end

    private
    attr_reader :window, :border_size, :errors, :decimals, :tick_spacing

    def debug?
      @debug
    end

    def border_char_map
      CharacterMap::DEFAULT
    end

    def inner_height
      rows - border_size.top - border_size.bottom
    end

    # At minimum, 2 cols of inner_width for values
    def min_cols
      border_size.left + border_size.right + 2
    end

    # At minimum, 2 rows of inner_height for values
    def min_rows
      border_size.top + border_size.bottom + 2
    end

    Border = Struct.new(:top, :right, :bottom, :left)
    def default_border_size
      Border.new(2, 4, 1, 1)
    end

    # Axis size = length of the longest point value , formatted as a string to
    # @decimals decimal places, + 2 for some extra buffer + 1 for the border
    # itself.
    def calculate_axis_size(series)
      border_right = series.data.map { |n| n.round(decimals).to_s.length }.max
      border_right += 3

      # Clamp border_right at cols - 3 to prevent the renderer from crashing
      # with very large numbers
      if border_right > cols - 3
        errors.push(Colors.yellow "Warning: Axis tick values have been clipped, consider using more columns with -c")
        border_right = cols - 3
      end

      @border_size = Border.new(2, border_right, 1, 1)
    end

    Point = Struct.new(:x, :y, :value)
    def build_points(series)
      return [] if series.data.empty?
      points =
        series.data.last(inner_width).map.with_index do |p, x|
          # Map from series Y range to inner height
          y = map_value(p, [series.min, series.max], [0, inner_height - 1])

          # Invert Y value since pixel Y is inverse of cartesian Y
          y = border_size.top - 1 + inner_height - y.round

          # Add padding for border width
          Point.new(x + border_size.left, y, p.to_f)
        end

      points
    end

    Tick = Struct.new(:y, :label)
    def build_ticks(points)
      return [] if points.empty?
      max_point = points.max_by(&:value)
      min_point = points.min_by(&:value)
      point_y_range = points.max_by(&:y).y - points.min_by(&:y).y
      point_value_range = max_point.value - min_point.value
      ticks = []
      ticks.push Tick.new(max_point.y, format_label(max_point.value))

      # Distribute ticks between min and max, maintaining spacinig as much as
      # possible. tick_spacing is inclusive of the tick row itself.
      unless max_point.value == min_point.value &&
             (point_y_range - 2) > tick_spacing
        num_ticks = (point_y_range - 2) / tick_spacing
        num_ticks.times do |i|
          tick_y = max_point.y + (i + 1) * tick_spacing
          value = max_point.value - point_value_range * ((i + 1) * tick_spacing) / point_y_range
          ticks.push Tick.new(tick_y, format_label(value))
        end
      end

      ticks.push Tick.new(min_point.y, format_label(min_point.value))
      ticks
    end

    # Map value from one range to another
    def map_value(val, from_range, to_range)
      orig_range = [1, (from_range[1] - from_range[0]).abs].max
      new_range = [1, (to_range[1] - to_range[0]).abs].max

      ((val.to_f - from_range[0]) / orig_range) * new_range + to_range[0]
    end

    def render_points(series, points)
      # Render points
      points.each_with_index do |point, i|
        window.cursor.position = point.y * cols + point.x
        if series.line_style[:extended]
          prev_point = ((i - 1) >= 0) ? points[i-1] : nil
          render_connected_line(series, prev_point, point)
        else
          window.write(colored(series, series.line_style[:point]))
        end
      end
    end

    def render_connected_line(series, prev_point, point)
      if prev_point.nil? || (prev_point.y == point.y)
        window.write(colored(series, series.line_style[:horz_top]))
      elsif prev_point.y > point.y
        diff = prev_point.y - point.y

        window.write(colored(series, series.line_style[:top_left]))
        window.cursor.down
        window.cursor.back

        (diff - 1).times do
          window.write(colored(series, series.line_style[:vert_right]))
          window.cursor.down
          window.cursor.back
        end

        window.write(colored(series, series.line_style[:bot_right]))
      elsif prev_point.y < point.y
        diff = point.y - prev_point.y

        window.write(colored(series, series.line_style[:bot_left]))
        window.cursor.up
        window.cursor.back

        (diff - 1).times do
          window.write(colored(series, series.line_style[:vert_left]))
          window.cursor.up
          window.cursor.back
        end

        window.write(colored(series, series.line_style[:top_right]))
      end
    end

    def render_title(series)
      legend_marker = colored(series, series.line_style[:point])
      title = series.title

      legend_position = [1, (border_size.left + 1 + inner_width) / 2 - (title.length + 2) / 2].max
      if (title.length + 2 + legend_position) > cols
        errors.push(Colors.yellow "Warning: Title has been clipped, consider using more rows with -r")
        title = title[0..(cols - legend_position - 2)]
      end

      window.cursor.forward(legend_position)
      window.write(legend_marker)
      window.write(" ")
      title.chars.each do |char|
        window.write(char)
      end
    end

    def render_borders
      window.cursor.down(border_size.top - 1)
      window.cursor.forward(border_size.left - 1)
      window.write(border_char_map[:top_left])
      inner_width.times { window.write(border_char_map[:horz_top]) }
      window.write(border_char_map[:top_right])
      window.cursor.forward(border_size.right - 1)

      inner_height.times do |y|
        window.cursor.forward(border_size.left - 1)
        window.write(border_char_map[:vert_right])
        window.cursor.forward(inner_width)
        window.write(border_char_map[:vert_left])
        window.cursor.forward(border_size.right - 1)
      end

      # Bottom border
      # Jump to bottom left corner
      window.cursor.forward(border_size.left - 1)
      window.write(border_char_map[:bot_left])
      inner_width.times { window.write(border_char_map[:horz_top]) }
      window.write(border_char_map[:bot_right])
    end

    def render_axis(ticks)
      window.cursor.down(border_size.top - 1)
      window.cursor.forward(border_size.left + inner_width + 1)

      # Render ticks
      ticks.each do |tick|
        window.cursor.row = tick.y
        window.cursor.back
        window.write(border_char_map[:tick_right])
        tick.label.chars.each do |c|
          window.write(c)
        end
        window.cursor.back(label_chars)
      end
    end

    def format_label(num)
      ("%.2f" % num.round(decimals))[0..label_chars - 1].ljust(label_chars, " ")
    end

    def label_chars
      border_size.right - 2
    end

    def colored(series, text)
      Colors.send(series.color, text)
    end
  end
end
