module Termplot
  class Series
    attr_reader :title, :data, :min, :max, :range, :color, :line_style
    attr_accessor :max_data_points

    DEFAULT_COLOR = "red"
    DEFAULT_LINE_STYLE = "line"

    def initialize(max_data_points:, title: "Series", color: DEFAULT_COLOR, line_style: DEFAULT_LINE_STYLE)
      @data = []
      @max_data_points = max_data_points
      @min = 0
      @max = 0
      @range = 0

      @title = title
      @color = Termplot::Colors.fetch(color, DEFAULT_COLOR)
      @line_style = Termplot::CharacterMap::LINE_STYLES.fetch(
        line_style,
        Termplot::CharacterMap::LINE_STYLES[DEFAULT_LINE_STYLE]
      )
    end

    def add_point(point)
      @data.push(point)

      while @data.length > max_data_points do
        @data.shift
      end

      @min = data.min
      @max = data.max
      @range = (max - min).abs
      @range = 1 if range.zero?
    end
  end
end
