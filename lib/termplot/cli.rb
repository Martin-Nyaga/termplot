# frozen_string_literal: true
require "termplot/options"

module Termplot
  class CLI
    def self.run
      options = Options.new.parse_options!
      run_consumer(options)
    end

    private

    CONSUMERS = {
      file:    "Termplot::Consumers::MultiSourceConsumer",
      command: "Termplot::Consumers::StdinConsumer",
      stdin:   "Termplot::Consumers::StdinConsumer",
    }
    def self.run_consumer(options)
      consumer = Object.const_get(CONSUMERS[options.mode])
      consumer.new(options).run
    end
  end
end
