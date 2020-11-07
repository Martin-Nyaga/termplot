module Termplot
  module Producers
    class CommandProducer < BaseProducer
      def run
        loop do
          n = `/bin/bash -c '#{options.command}'`.chomp
          # TODO: Error handling...

          if numeric?(n)
            queue << n.to_f
            consumer&.run
          end

          # Interval is in ms
          sleep(options.interval / 1000.0)
        end
      end
    end
  end
end
