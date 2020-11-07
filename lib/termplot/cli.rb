# frozen_string_literal: true
require "termplot/options"
require "termplot/consumer"

module Termplot
  class CLI
    def self.run
      opts = Options.new.parse_options!
      Consumer.new(opts).run
    end
  end
end
