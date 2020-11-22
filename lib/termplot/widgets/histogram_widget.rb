# frozen_string_literal: true

require "termplot/window"
require "termplot/renderable"
require "termplot/window"
require "termplot/character_map"
require "termplot/renderers"
require "termplot/colors"

module Termplot
  module Widgets
    class HistogramWidget < BaseWidget
      include Termplot::Renderers::BorderRenderer
      include Termplot::Renderers::TextRenderer

      DEFAULT_COLOR = "green"

      def initialize(
        title: "Histogram",
        cols:,
        rows:,
        color: DEFAULT_COLOR,
        debug: false
      )
        @border_size = default_border_size
        @cols = cols > min_cols ? cols : min_cols
        @rows = rows > min_rows ? rows : min_rows

        @window = Window.new(
          cols: @cols,
          rows: @rows
        )
        @color = color

        @debug = debug
        @errors = []

        @title = bin_char + " " + title

        @decimals = 2

        # TODO: Make max count configurable
        @max_count = 10_000
        @decimals = 2
        @dataset = Dataset.new(max_count)
      end

      def <<(point)
        dataset << point
        dataset.set_capacity(max_count)
      end

      def render_to_window
        errors.clear
        window.clear
        window.cursor.reset_position

        bins = bin_data(calculate_bins)
        bins_to_render = calculate_bin_coordinates(bins)
        calculate_axis_size(bins_to_render)
        render_bins(bins_to_render)
        window.cursor.reset_position

        # Title bar
        render_aligned_text(
          window: window,
          text: title,
          row: 0,
          border_size: border_size,
          inner_width: inner_width,
          errors: errors
        )

        window.cursor.reset_position

        # Borders
        render_borders(
          window: window,
          inner_width: inner_width,
          inner_height: inner_height
        )

        window.cursor.reset_position

        # Ticks
        render_ticks(bins_to_render)
      end

      private
      attr_reader :max_count, :decimals, :border_size, :color

      def default_border_size
        Border.new(2, 1, 1, 4)
      end

      def calculate_axis_size(bins)
        return border_size if bins.empty?
        border_left = bins.map { |bin| bin.midpoint.round(decimals).to_s.length }.max
        border_left += 2

        # Clamp border_left to prevent the renderer from crashing
        # with very large numbers
        if border_left > cols - 5
          errors.push(Colors.yellow("Warning: Axis tick values have been clipped, consider using more columns with -c"))
          border_left = cols - 5
        end

        @border_size = Border.new(2, 1, 1, border_left)
      end

      def min_cols
        border_size.left + border_size.right + 5
      end

      def num_bins
        inner_height
      end

      def min_rows
        border_size.top + border_size.bottom + 1
      end

      def render_bins(positioned_bins)
        positioned_bins.each do |bin|
          window.cursor.beginning_of_line
          window.cursor.row = bin.y + border_size.top
          window.cursor.forward(border_size.left)
          bin.x.times { window.write(bin_char) }
          window.write(" ")

          bin.count.to_s.chars.each do |char|
            window.write(char)
          end
        end
      end

      def render_ticks(positioned_bins)
        positioned_bins.each do |bin|
          window.cursor.row = bin.y + border_size.top
          window.cursor.beginning_of_line

          bin.midpoint.round(decimals).to_s.rjust(border_size.left - 1, " ").chars.first(border_size.left - 1).each do |c|
            window.write(c)
          end
        end
      end

      PositionedBin = Struct.new(:bin, :x, :y) do
        extend(Forwardable)
        def_delegators(:bin, :count, :min, :max, :midpoint)
      end

      def calculate_bin_coordinates(bins)
        return [] unless bins.any?
        max_count = bins.max_by { |bin| bin.count }&.count

        bins.map.with_index do |bin, i|
          row = i
          # Save some chars for count
          col = ((bin.count.to_f / max_count) * (inner_width - 4)).floor
          PositionedBin.new(bin, col, row)
        end
      end

      def bin_data(bins)
        return [] unless bins.any?

        dataset.each do |value|
          bin = bins.find { |b| b.min <= value && b.max > value }
          bin.count += 1 unless bin.nil?
        end

        bins
      end

      Bin = Struct.new(:min, :max, :count) do
        def size
          max - min
        end

        def midpoint
          (max + min) / 2
        end
      end

      def calculate_bins
        return [] if dataset.empty?

        min = dataset.min
        max = dataset.max
        bin_size = dataset.range.to_f / num_bins.to_f

        if bin_size.zero?
          min -= 1
          max += 1
          bin_size = 1
        end

        bins = []
        while min < max && bins.length < num_bins
          bins.push(Bin.new(min, min + bin_size, 0))
          min += bin_size
        end

        # Correct for floating point errors on max bin
        if bins.any?
          bins.last.max = max if bins.last.max < max
        end

        bins
      end

      def bin_char
        Colors.send(color, "▇")
      end
    end
  end
end
