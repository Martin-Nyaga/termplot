
require "termplot/positioned_widget"
require "termplot/widgets"
require "termplot/producers"

module Termplot
  module Consumers
    class CommandConsumer < SingleSourceConsumer
      def producer_class
        Termplot::Producers::CommandProducer
      end
    end
  end
end
