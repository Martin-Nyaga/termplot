require "termplot/series"
require "termplot/renderer"
require "termplot/shell"

module Termplot
  class Consumer
    attr_reader :series, :renderer

    def initialize(
      cols:,
      rows:,
      title:,
      line_style:,
      color:,
      debug:,
      command:,
      interval:
    )
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
      @command = command
      @interval = interval
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
      if @command
        WatchProducer.new(queue, @command, @interval)
      else
        StdinProducer.new(queue)
      end
    end

    class Producer
      def initialize(queue)
        @queue = queue
        @consumer = nil
      end

      def register_consumer(consumer)
        @consumer = consumer
      end

      def shift
        queue.shift
      end

      def closed?
        queue.closed?
      end

      def close
        queue.close
      end

      private
      attr_reader :queue, :consumer

      FLOAT_REGEXP = /^[-+]?[0-9]*\.?[0-9]+$/
      def numeric?(n)
        n =~ FLOAT_REGEXP
      end
    end

    class StdinProducer < Producer
      def run
        while n = STDIN.gets&.chomp do
          if numeric?(n)
            queue << n.to_f
            consumer&.run
          end
        end
      end
    end

    class WatchProducer < Producer
      attr_reader :command, :interval

      def initialize(queue, command, interval)
        @command = command
        # Interval is in ms
        @interval = interval / 1000
        super(queue)
      end

      def run
        loop do
          n = `/bin/bash -c '#{command}'`.chomp
          # TODO: Error handling...

          if numeric?(n)
            queue << n.to_f
            consumer&.run
          end

          sleep interval
        end
      end
    end
  end
end
