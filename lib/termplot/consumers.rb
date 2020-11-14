module Termplot
  module Consumers
    autoload :BaseConsumer, "termplot/consumers/base_consumer"
    autoload :MultiSourceConsumer, "termplot/consumers/multi_source_consumer"
    autoload :SingleSourceConsumer, "termplot/consumers/single_source_consumer"

    autoload :StdinConsumer, "termplot/consumers/stdin_consumer"
    autoload :CommandConsumer, "termplot/consumers/command_consumer"
  end
end
