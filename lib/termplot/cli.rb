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
      options = { rows: 19, cols: 80, title: "Series", debug: false }
      OptionParser.new do |opts|
        opts.banner = "Usage: termplot [OPTIONS]"

        opts.on("-rROWS", "--rows=ROWS", "Number of rows in window") do |v|
          options[:rows] = v.to_i
        end

        opts.on("-cCOLS", "--cols=COLS", "Number of cols in window") do |v|
          options[:cols] = v.to_i
        end

        opts.on("-tTITLE", "--title=TITLE", "Title of the series") do |v|
          options[:title] = v
        end

        opts.on("-d", "--debug", "Enable debug mode, Logs window data to stdout instead of rendering") do |v|
          options[:debug] = v
        end

        opts.on("-h", "--help", "Prints this help") do
          puts opts
          exit(0)
        end

      end.parse!
      options
    end
  end
end
