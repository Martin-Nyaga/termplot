# frozen_string_literal: true

require "optparse"

module Termplot
  class Options
    attr_reader :rows,
                :cols,
                :title,
                :line_style,
                :color,
                :debug,
                :command,
                :interval

    def initialize
      @rows       = 19
      @cols       = 80
      @title      = "Series"
      @line_style = "line"
      @color      = "red"
      @debug      = false
      @command    = nil
      @interval   = 1000
    end

    def mode
      @command.nil? ? :stdin : :command
    end

    def parse_options!
     OptionParser.new do |opts|
        opts.banner = "Usage: termplot [OPTIONS]"

        opts.on("-rROWS", "--rows ROWS", "Number of rows in the chart window (default: 19)") do |v|
          @rows = v.to_i
        end

        opts.on("-cCOLS", "--cols COLS", "Number of cols in the chart window (default: 80)") do |v|
          @cols = v.to_i
        end

        opts.on("-tTITLE", "--title TITLE", "Title of the series (default: Series)") do |v|
          @title = v
        end

        opts.on("--line-style STYLE", "Line style. Options are: line [default], heavy-line, dot, star, x") do |v|
          @line_style = v.downcase
        end

        opts.on("--color COLOR", "Series color, specified as ansi 16-bit color name",
                "(i.e. black, red [default], green, yellow, blue, magenta, cyan, white)",
                "with light versions specified as light_{color}") do |v|
          @color = v.downcase
        end

        opts.on("--command COMMAND", "Enables command mode, where input is received by executing",
                                     "the specified command in intervals rather than from stdin") do |v|
          @command = v
        end

        opts.on("--interval INTERVAL", "The interval at which to run the specified command in command mode in ms (default 1000)") do |v|
          @interval = v.to_i
          pp @interval
        end

        opts.on("-d", "--debug", "Enable debug mode, Logs window data to stdout instead of rendering") do |v|
          @debug = v
        end

        opts.on("-h", "--help", "Display this help message") do
          puts opts
          exit(0)
        end
      end.parse!
      self
    end
  end
end
