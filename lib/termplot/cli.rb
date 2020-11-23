# frozen_string_literal: true
require "termplot/options"
require "termplot/consumers"

module Termplot
  class CLI
    def self.run
      options = Termplot::Options.new
      options.parse_options!
      run_consumer(options)
    end

    private

    CONSUMERS = {
      file:    "Termplot::Consumers::MultiSourceConsumer",
      command: "Termplot::Consumers::CommandConsumer",
      stdin:   "Termplot::Consumers::StdinConsumer",
    }
    def self.run_consumer(options)
      consumer = Object.const_get(CONSUMERS[options.input_mode])
      consumer.new(options).run
    end
  end
end
