require "termplot/widgets/statistics"

module Termplot
  module Widgets
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
