# frozen_string_literal: true

require "termplot/window"
require "termplot/character_map"
require "termplot/colors"
require "termplot/renderable"
require "termplot/renderers"

module Termplot
  module Widgets
    class TimeSeriesWidget < BaseWidget
      DEFAULT_COLOR = "yellow"
      DEFAULT_LINE_STYLE = "line"

      attr_reader :color, :line_style, :tick_spacing

      def post_initialize(opts)
        @color = Termplot::Colors.fetch(opts[:color], DEFAULT_COLOR)
        @line_style = Termplot::CharacterMap::LINE_STYLES.fetch(
          opts[:line_style],
          Termplot::CharacterMap::LINE_STYLES[DEFAULT_LINE_STYLE]
        )

        @tick_spacing = 3
      end

      def render_to_window
        errors.clear
        window.clear

        # Calculate width of right hand axis
        calculate_axis_size

        # Points
        points = build_points
        render_points(points)
        window.cursor.reset_position

        # Title bar
        Termplot::Renderers::TextRenderer.new(
          bordered_window: bordered_window,
          text: title_text,
          row: 0,
          errors: errors
        ).render
        window.cursor.reset_position

        # Borders
        Termplot::Renderers::BorderRenderer.new(
          bordered_window: bordered_window
        ).render

        window.cursor.reset_position

        # Draw axis
        ticks = build_ticks(points)
        render_axis(ticks)
      end

      private
      def max_count
        bordered_window.inner_width
      end

      # Axis size = length of the longest point value , formatted as a string to
      # @decimals decimal places, + 2 for some extra buffer + 1 for the border
      # itself.
      def calculate_axis_size
        return if dataset.empty?
        border_right = dataset.map { |n| n.round(decimals).to_s.length }.max
        border_right += 3

        # Clamp border_right at cols - 3 to prevent the renderer from crashing
        # with very large numbers
        if border_right > cols - 3
          errors.push(Colors.yellow("Warning: Axis tick values have been clipped, consider using more columns with -c"))
          border_right = cols - 3
        end

        @bordered_window.border_size = Border.new(2, border_right, 1, 1)
      end

      def border_char_map
        CharacterMap::DEFAULT
      end

      def default_border_size
        Border.new(2, 4, 1, 1)
      end

      # At minimum, 2 cols of inner_width for values
      def min_cols
        default_border_size.left + default_border_size.right + 2
      end

      # At minimum, 2 rows of inner_height for values
      def min_rows
        default_border_size.top + default_border_size.bottom + 2
      end

      Point = Struct.new(:x, :y, :value)
      def build_points
        return [] if dataset.empty?

        dataset.map.with_index do |p, x|
          # Map from series Y range to inner height
          y = map_value(p, [dataset.min, dataset.max], [0, bordered_window.inner_height - 1])

          # Invert Y value since pixel Y is inverse of cartesian Y
          y = bordered_window.border_size.top - 1 + bordered_window.inner_height - y.round

          # Add padding for border width
          Point.new(x + bordered_window.border_size.left, y, p.to_f)
        end
      end

      def render_points(points)
        # Render points
        points.each_with_index do |point, i|
          window.cursor.position = point.y * cols + point.x

          if line_style[:extended]
            prev_point = ((i - 1) >= 0) ? points[i - 1] : nil
            render_connected_line(prev_point, point)
          elsif line_style[:filled]
            render_filled_point(point)
          else
            window.write(colored(line_style[:point]))
          end
        end
      end

      def render_connected_line(prev_point, point)
        if prev_point.nil? || (prev_point.y == point.y)
          window.write(colored(line_style[:horz_top]))
        elsif prev_point.y > point.y
          diff = prev_point.y - point.y

          window.write(colored(line_style[:top_left]))
          window.cursor.down
          window.cursor.back

          (diff - 1).times do
            window.write(colored(line_style[:vert_right]))
            window.cursor.down
            window.cursor.back
          end

          window.write(colored(line_style[:bot_right]))
        elsif prev_point.y < point.y
          diff = point.y - prev_point.y

          window.write(colored(line_style[:bot_left]))
          window.cursor.up
          window.cursor.back

          (diff - 1).times do
            window.write(colored(line_style[:vert_left]))
            window.cursor.up
            window.cursor.back
          end

          window.write(colored(line_style[:top_right]))
        end
      end

      def render_filled_point(point)
        diff = (bordered_window.inner_height + bordered_window.border_size.bottom) - point.y
        diff.times { window.cursor.down }

        diff.times do
          window.write(Colors.send("#{color}_bg", colored(line_style[:point])))
          window.cursor.up
          window.cursor.back
        end

        window.write(colored(line_style[:point]))
      end

      Tick = Struct.new(:y, :label)
      def build_ticks(points)
        return [] if points.empty?
        max_point = points.max_by(&:value)
        min_point = points.min_by(&:value)
        point_y_range = points.max_by(&:y).y - points.min_by(&:y).y
        ticks = []
        ticks.push(Tick.new(max_point.y, format_label(max_point.value)))

        # Distribute ticks between min and max, maintaining spacinig as much as
        # possible. tick_spacing is inclusive of the tick row itself.
        if max_point.value != min_point.value && (point_y_range - 2) > tick_spacing
          num_ticks = (point_y_range - 2) / tick_spacing

          num_ticks.times do |i|
            tick_y = max_point.y + (i + 1) * tick_spacing
            value = max_point.value - dataset.range * ((i + 1) * tick_spacing) / point_y_range
            ticks.push(Tick.new(tick_y, format_label(value)))
          end
        end

        ticks.push(Tick.new(min_point.y, format_label(min_point.value)))
        ticks
      end

      # Map value from one range to another
      def map_value(val, from_range, to_range)
        orig_range = [1, (from_range[1] - from_range[0]).abs].max
        new_range = [1, (to_range[1] - to_range[0]).abs].max

        ((val.to_f - from_range[0]) / orig_range) * new_range + to_range[0]
      end

      def title_text
        colored(line_style[:point]) + " " + title
      end

      def render_axis(ticks)
        window.cursor.down(bordered_window.border_size.top - 1)
        window.cursor.forward(bordered_window.border_size.left + bordered_window.inner_width + 1)

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
        ("%.#{decimals}f" % num.round(decimals))[0..label_chars - 1].ljust(label_chars, " ")
      end

      def label_chars
        bordered_window.border_size.right - 2
      end

      def colored(text)
        Colors.send(color, text)
      end
    end
  end
end
