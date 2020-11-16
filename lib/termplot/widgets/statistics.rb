module Termplot
  module Widgets
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
  end
end
