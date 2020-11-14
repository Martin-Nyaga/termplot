require "termplot/producers"

module Termplot
  module Consumers
    class StdinConsumer < SingleSourceConsumer
      def producer_class
        Termplot::Producers::StdinProducer
      end
    end
  end
end
