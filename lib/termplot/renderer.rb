# frozen_string_literal: true

require "termplot/window"
require "termplot/character_map"
require "termplot/shell"

module Termplot
  class Renderer
    attr_reader :cols, :rows, :window, :char_map

    def initialize(cols: 80, rows: 20, debug: false)
      @cols = cols
      @rows = rows
      @window = Window.new(cols: cols, rows: rows)
      @debug = debug
      @drawn = false
      @char_map = CharacterMap::DEFAULT

      Shell.init
    end

    def render(series)
      window.clear

      # Build points, ticks to render
      points = build_points(series)
      ticks = build_ticks(points)

      # Render points
      points.each_with_index do |point, i|
        window.cursor.position = point.y * cols + point.x
        if char_map[:extended]
          prev_point = ((i - 1) >= 0) ? points[i-1] : nil
          render_connected_line(prev_point, point)
        else
          window.write(char_map[:point])
        end
      end

      window.cursor.reset_position

      # Title bar
      legend = "#{char_map[:point]} #{series.title}"
      legend_position = [1, (border_size.left + 1 + inner_width) / 2 - legend.length / 2].max
      window.cursor.forward(legend_position)
      legend.chars.each do |char|
        window.write(char)
      end
      window.cursor.reset_position

      # Top borders
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

      # Draw axis
      window.cursor.reset_position
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

      debug? ?
        window.flush_debug :
        window.flush
    end

    def inner_width
      cols -  border_size.left - border_size.right
    end

    private

    def debug?
      @debug
    end

    def border_char_map
      CharacterMap::DEFAULT
    end

    def inner_height
      rows - border_size.top - border_size.bottom
    end

    Border = Struct.new(:top, :right, :bottom, :left)
    def border_size
      @border_size ||= Border.new(2, 10, 1, 1)
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
      point_value_range = points.max_by(&:value).value - points.min_by(&:value).value
      ticks = []
      ticks.push Tick.new(max_point.y, format_label(max_point.value))

      # Distribute ticks between min and max as evenly as possible

      # spacing is inclusive of the tick row itself
      spacing = 3
      unless max_point.value == min_point.value &&
          (point_y_range - 2) > spacing
        num_ticks = (point_y_range - 2) / spacing
        num_ticks.times do |i|
          tick_y = max_point.y + (i + 1) * spacing
          value = max_point.value - point_value_range * ((i + 1) * spacing) / point_y_range
          ticks.push Tick.new(tick_y, format_label(value))
        end
      end

      ticks.push Tick.new(min_point.y, format_label(min_point.value))
      ticks
    end

    def map_value(val, from_range, to_range)
      orig_range = [1, (from_range[1] - from_range[0]).abs].max
      new_range = [1, (to_range[1] - to_range[0]).abs].max

      ((val.to_f - from_range[0]) / orig_range) * new_range + to_range[0]
    end

    def render_connected_line(prev_point, point)
      if prev_point.nil? || (prev_point.y == point.y)
        window.write(char_map[:horz_top])
      elsif prev_point.y > point.y
        diff = prev_point.y - point.y
        window.cursor.down diff
        window.write(char_map[:bot_right])
        window.cursor.back
        (diff - 1).times do
          window.cursor.up
          window.write(char_map[:vert_right])
          window.cursor.back
        end
        window.cursor.up
        window.write(char_map[:top_left])
      elsif prev_point.y < point.y
        diff = point.y - prev_point.y
        window.cursor.up diff
        window.write(char_map[:top_right])
        window.cursor.back
        (diff - 1).times do
          window.cursor.down
          window.write(char_map[:vert_left])
          window.cursor.back
        end
        window.cursor.down
        window.write(char_map[:bot_left])
      end
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
