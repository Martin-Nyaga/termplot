require_relative "./lib/termplot/commands"
require "bundler/gem_tasks"

extend Termplot::Commands
extend Termplot::StdinCommands

SAMPLE_FILE = "./sample.rb"
def termplot_binary
  "ruby -Ilib bin/termplot"
end

namespace :test do
  task :bin do
    exec "ruby", "-Ilib", "bin/termplot", *ARGV[2..-1]
  end

  task :file do
    cmd = %( #{termplot_binary} -f #{SAMPLE_FILE} -r30 -c100)
    exec cmd 
  end

  namespace :timeseries do
    task :sin do
      cmd = "#{sin(500)} | #{termplot_binary} -t 'sin(x)'"
      exec cmd
    end

    task :random do
      cmd = %( #{termplot_binary} --command '#{random}' --interval 900% )
      exec cmd
    end
  end
end
