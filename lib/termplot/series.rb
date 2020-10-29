module Termplot
  class Series
    attr_reader :data, :min, :max, :range, :max_data_points
    def initialize(max_data_points:)
      @data = []
      @max_data_points = max_data_points
      @min = 0
      @max = 0
      @range = 0
    end

    def add_point(point)
      @data.push(point)

      while @data.length > max_data_points do
        @data.shift
      end

      @min = data.min
      @max = data.max
      @range = max - min
      @range = 1 if range.zero?
    end
  end
end
