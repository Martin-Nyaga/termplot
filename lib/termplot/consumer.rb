require "termplot/series"
require "termplot/renderer"
require "termplot/shell"

module Termplot
  class Consumer
    attr_reader :series, :renderer

    def initialize(cols:, rows:, title:, line_style:, color:, debug:)
      @renderer = Renderer.new(
        cols: cols,
        rows: rows,
        debug: debug
      )
      @series = Series.new(
        title: title,
        max_data_points: renderer.inner_width,
        line_style: line_style,
        color: color,
      )
    end

    def run
      Shell.init
      queue = Queue.new

      # Consumer thread will process and render any available input in the
      # queue. If samples are available faster than it can render, multiple
      # samples will be shifted from the queue so they can be rendered at once.
      # If no samples are available but stdin is open, it will sleep until
      # woken to render new input.
      consumer = Thread.new do
        while !queue.closed?
          num_samples = queue.size
          if num_samples == 0
            Thread.stop
          else
            num_samples.times do
              series.add_point(queue.shift)
            end

            renderer.render(series)
            series.max_data_points = renderer.inner_width
          end
        end
      end

      # Main thread will accept samples as fast as they become available from stdin,
      # and wake the consumer thread to process them if its asleep
      while n = STDIN.gets&.chomp do
        if numeric?(n)
          queue << n.to_f
          consumer.run
        end
      end

      # Queue is closed as soon as stdin is closed, and we wait for the consumer
      # to finish rendering
      queue.close
      consumer.run
      consumer.join
    end

    private

    FLOAT_REGEXP = /^[-+]?[0-9]*\.?[0-9]+$/
    def numeric?(n)
      n =~ FLOAT_REGEXP
    end
  end
end
