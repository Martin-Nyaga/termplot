module Termplot
  module Producers
    class StdinProducer < BaseProducer
      def run
        while n = STDIN.gets&.chomp do
          if numeric?(n)
            queue << n.to_f
            consumer&.run
          end
        end
      end
    end
  end
end
