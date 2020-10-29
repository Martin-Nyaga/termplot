require "termplot/series"
require "termplot/renderer"

module Termplot
  class Consumer
    attr_reader :series, :renderer

    def initialize(cols:, rows:, debug:)
      @renderer = Renderer.new(cols: cols, rows: rows, debug: debug)
      @series = Series.new(max_data_points: renderer.inner_width)
    end

    def run
      while n = STDIN.gets&.chomp do
        series.add_point(n.to_f)
        renderer.render(series)
      end
    end
  end
end
