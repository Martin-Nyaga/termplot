module Termplot
  module Producers
    class CommandProducer < BaseProducer
      def run
        command = sanitize_command("/bin/bash -c '#{options.command}'")
        loop do
          n = `#{command}`
          # TODO: Error handling...

          if numeric?(n)
            queue << n.to_f
            consumer&.run
          end

          # Interval is in ms
          sleep(options.interval / 1000.0)
        end
      end

      private
        def sanitize_command(command)
          command.gsub(/\$/, '\\$')
        end
    end
  end
end
