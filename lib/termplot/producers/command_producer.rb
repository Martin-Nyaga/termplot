module Termplot
  module Producers
    class CommandProducer < BaseProducer
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
