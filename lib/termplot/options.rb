# frozen_string_literal: true

require "optparse"
require "termplot/character_map"
require "termplot/colors"
require "termplot/producer_options"

module Termplot
  class Options
    attr_reader :rows,
                :cols,
                :file,
                :title,
                :line_style,
                :color,
                :debug,
                :command,
                :interval

    def initialize
      @rows       = 19
      @cols       = 80
      @fie        = nil
      @title      = "Series"
      @line_style = "line"
      @color      = "red"
      @debug      = false
      @command    = nil
      @interval   = 1000
    end

    # 3 modes supported:
    # - Read from stdin and render a single chart (default)
    # - Run a single command at an interval and render a single chart
    # - Read configuration from a file, run multiple commands at an interval and
    #   render a dashboard
    def mode
      return :file    unless @file.nil?
      return :command unless @command.nil?
      :stdin
    end

    def parse_options!
      # Debug option is parsed manually to prevent it from showing up in the
      # options help
      parse_debug

      OptionParser.new do |opts|
        opts.banner = "Usage: termplot [OPTIONS]"

        parse_rows(opts)
        parse_cols(opts)

        parse_command(opts)
        parse_interval(opts)

        parse_file(opts)

        parse_title(opts)
        parse_line_style(opts)
        parse_color(opts)


        opts.on("-h", "--help", "Display this help message") do
          puts opts
          exit(0)
        end

      end.parse!
      self
    end

    def producer_options
      ProducerOptions.new(command: command, interval: interval)
    end

    private

    def parse_rows(opts)
      opts.on("-r ROWS", "--rows ROWS",
              "Number of rows in the chart window (default: #{@rows})") do |v|
        @rows = v.to_i
      end
    end

    def parse_cols(opts)
      opts.on("-c COLS", "--cols COLS",
              "Number of cols in the chart window (default: #{@cols})") do |v|
        @cols = v.to_i
      end
    end

    def parse_file(opts)
      opts.on("-f FILE", "--file FILE",
              "Read a dashboard configuration from a file") do |v|
        @file = v
      end
    end

    def parse_title(opts)
      opts.on("-tTITLE", "--title TITLE",
              "Title of the series (default: '#{@title}')") do |v|
        @title = v
      end
    end

    def parse_line_style(opts)
      line_style_opts = with_default(Termplot::CharacterMap::LINE_STYLES.keys, @line_style)
      opts.on("--line-style STYLE",
              "Line style. Options are: #{line_style_opts.join(", ")}") do |v|
        @line_style = v.downcase
      end
    end

    def parse_color(opts)
      color_opts = Termplot::Colors::COLORS.keys.map(&:to_s).reject do |c|
        c == :default
      end
      color_opts = with_default(color_opts, @color)
      opts.on("--color COLOR",
              "Series color, specified as ansi 16-bit color name:",
              "(i.e. #{color_opts.join(", ")})") do |v|
        @color = v.downcase
      end
    end

    def parse_command(opts)
      opts.on("--command COMMAND",
              "Enables command mode, where input is received by executing",
              "the specified command in intervals rather than from stdin") do |v|
        @command = v
      end
    end

    def parse_interval(opts)
      opts.on("--interval INTERVAL",
              "The interval at which to run the specified command in",
              "command mode in milliseconds (default: #{@interval})") do |v|
        @interval = v.to_i
      end
    end

    def parse_debug
      if ARGV.delete("--debug") || ARGV.delete("-d")
        @debug = true
      end
    end

    def with_default(opt_arr, default)
      opt_arr.map do |opt|
        opt == default ?
          opt + " (default)" :
          opt
      end
    end
  end
end
