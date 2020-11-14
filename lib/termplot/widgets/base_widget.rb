module Termplot
  module Widgets
    class BaseWidget
      include Renderable

      attr_reader :window, :errors

      def <<(point)
        raise "Must be implemented"
      end

      def render_to_window
        raise "Must be implemented"
      end

      private
      attr_reader :cols, :rows, :dataset, :title
    end

    class Border < Struct.new(:top, :right, :bottom, :left)
    end

    module Statistics
      def count
        data.count
      end

      def mean
        return 0 if data.empty?
        data.sum(0.0) / count
      end

      def standard_deviation
        return 0 if data.empty?
        data_mean = mean
        variance = data.map { |x| (data_mean - x) ** 2 }.sum / count
        Math.sqrt(variance)
      end
    end

    class Dataset
      include Enumerable
      include Statistics

      attr_reader :capacity, :min, :max, :range, :data

      def initialize(capacity)
        @data = []
        @min = 0
        @max = 0
        @range = 0
        @capacity = capacity
      end

      def each(&block)
        data.each(&block)
      end

      def << (point)
        data.push(point)

        discard_excess

        @min = data.min
        @max = data.max
        @range = (max - min).abs
        @range = 1 if range.zero?
      end

      def set_capacity(capacity)
        @capacity = capacity
        discard_excess
      end

      def empty?
        data.empty?
      end

      private
      def discard_excess
        excess = [0, data.length - capacity].max
        data.shift(excess)
      end
    end

  end
end
