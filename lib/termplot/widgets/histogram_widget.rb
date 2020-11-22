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
      DEFAULT_COLOR = "green"
      attr_reader :color

      def post_initialize(opts)
        @color = opts[:color] || DEFAULT_COLOR
      end

      def render_to_window
        errors.clear
        window.clear
        window.cursor.reset_position

        bins = calculate_bins
        bins = bin_data(bins)
        bins = calculate_bin_coordinates(bins)
        calculate_axis_size(bins)
        render_bins(bins)
        window.cursor.reset_position

        # Ticks
        render_ticks(bins)
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
      end

      private

      def default_border_size
        Border.new(2, 1, 1, 4)
      end

      def calculate_axis_size(bins)
        return if bins.empty?
        border_left = bins.map { |bin| bin.midpoint.round(decimals).to_s.length }.max
        border_left += 2

        # Clamp border_left to prevent the renderer from crashing
        # with very large numbers
        if border_left > cols - 5
          errors.push(Colors.yellow("Warning: Axis tick values have been clipped, consider using more columns with -c"))
          border_left = cols - 5
        end

        @bordered_window.border_size = Border.new(2, 1, 1, border_left)
      end

      def min_cols
        default_border_size.left + default_border_size.right + 5
      end

      def num_bins
        bordered_window.inner_height
      end

      def min_rows
        default_border_size.top + default_border_size.bottom + 1
      end

      def title_text
        bin_char + " " + title
      end

      def render_bins(positioned_bins)
        positioned_bins.each do |bin|
          window.cursor.beginning_of_line
          window.cursor.row = bin.y + bordered_window.border_size.top
          window.cursor.forward(bordered_window.border_size.left)
          bin.x.times { window.write(bin_char) }
          window.write(" ")

          bin.count.to_s.chars.each do |char|
            window.write(char)
          end
        end
      end

      def render_ticks(positioned_bins)
        positioned_bins.each do |bin|
          window.cursor.row = bin.y + bordered_window.border_size.top
          window.cursor.beginning_of_line

          bin.midpoint.round(decimals).to_s.rjust(bordered_window.border_size.left - 1, " ").chars.first(bordered_window.border_size.left - 1).each do |c|
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
          col = ((bin.count.to_f / max_count) * (bordered_window.inner_width - 4)).floor
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
