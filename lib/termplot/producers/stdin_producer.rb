module Termplot
  module Producers
    class StdinProducer < BaseProducer
      def run
        while n = STDIN.gets&.chomp do
          produce(n)
        end
      end
    end
  end
end
