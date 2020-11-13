require "tempfile"
require "fileutils"

module Termplot
  module Producers
    class CommandProducer < BaseProducer
      def run
        temp_executable = make_executable(options.command)
        loop do
          n = `#{temp_executable.path}`.chomp
          # TODO: Error handling...

          produce(n)

          # Interval is in ms
          sleep(options.interval / 1000.0)
        end
      ensure
        temp_executable.unlink
      end

      private
      def make_executable(command)
        file = Tempfile.new
        file.write <<~COMMAND
          #! #{ENV['SHELL']}
          echo $(#{sanitize_command(command)})
        COMMAND
        file.close

        FileUtils.chmod("a=xrw", file.path)
        file
      end

      def sanitize_command(command)
        # command.gsub('"', "'")
        command
      end
    end
  end
end
