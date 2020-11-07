require "termplot/series"
require "termplot/renderer"
require "termplot/shell"
require "termplot/producers"

module Termplot
  class Consumer
    attr_reader :options, :series, :renderer

    def initialize(options)
      @options = options
      @renderer = Renderer.new(
        cols: options.cols,
        rows: options.rows,
        debug: options.debug
      )
      @series = Series.new(
        title: options.title,
        max_data_points: renderer.inner_width,
        line_style: options.line_style,
        color: options.color,
      )
    end

    def run
      Shell.init
      queue = Queue.new

      # Consumer thread will process and render any available input in the
      # queue. If samples are available faster than it can render, multiple
      # samples will be shifted from the queue so they can be rendered at once.
      # If no samples are available but the queue is open, it will sleep until
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

      # Producer will run in the main thread and will block while producing
      # samples from some source (which depends on the type of producer).
      # Samples will be added to the queue as they are available, and the
      # consumer will be woken to check the queue
      producer = build_producer(queue)
      producer.register_consumer(consumer)
      producer.run

      # As soon as producer continues, and we first give the consumer a chance
      # to finish rendering the queue, then close the queue.
      consumer.run
      producer.close
      consumer.join
    end

    private

    def build_producer(queue)
      producer_class = {
        command: "Termplot::Producers::CommandProducer",
        stdin: "Termplot::Producers::StdinProducer"
      }.fetch(options.mode)
      Object.const_get(producer_class).new(queue, options)
    end
  end
end
