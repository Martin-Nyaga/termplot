# frozen_string_literal: true
require "termplot/options"

module Termplot
  class CLI
    def self.run
      opts = Options.new.parse_options!
      opts.run_consumer
    end
  end
end
