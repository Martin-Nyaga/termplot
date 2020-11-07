# frozen_string_literal: true

require "optparse"
require "termplot/consumer"

module Termplot
  class CLI
    def self.run
      opts = self.parse_options
      Consumer.new(**opts).run
    end

    private
    def self.parse_options
      options = {
        rows: 19,
        cols: 80,
        title: "Series",
        line_style: "line",
        color: "red",
        debug: false,
        command: nil,
        interval: 1000
      }
      OptionParser.new do |opts|
        opts.banner = "Usage: termplot [OPTIONS]"

        opts.on("-rROWS", "--rows ROWS", "Number of rows in the chart window (default: 19)") do |v|
          options[:rows] = v.to_i
        end

        opts.on("-cCOLS", "--cols COLS", "Number of cols in the chart window (default: 80)") do |v|
          options[:cols] = v.to_i
        end

        opts.on("-tTITLE", "--title TITLE", "Title of the series (default: Series)") do |v|
          options[:title] = v
        end

        opts.on("--line-style STYLE", "Line style. Options are: line [default], heavy-line, dot, star, x") do |v|
          options[:line_style] = v.downcase
        end

        opts.on("--color COLOR", "Series color, specified as ansi 16-bit color name",
                "(i.e. black, red [default], green, yellow, blue, magenta, cyan, white)",
                "with light versions specified as light_{color}") do |v|
          options[:color] = v.downcase
        end

        opts.on("--command COMMAND", "Enables watch mode, where input is received by executing",
                                     "the specified command in intervals rather than from stdin") do |v|
          options[:command] = v
        end

        opts.on("--interval INTERVAL", "The interval at which to run the specified command in watch mode in ms (default 1000)") do |v|
          options[:interval] = v.to_i
        end

        opts.on("-d", "--debug", "Enable debug mode, Logs window data to stdout instead of rendering") do |v|
          options[:debug] = v
        end

        opts.on("-h", "--help", "Display this help message") do
          puts opts
          exit(0)
        end

      end.parse!
      options
    end
  end
end
