require "bundler/gem_tasks"

task :bin do
  Bundler.require(:default)
  exec "bin/termplot", *ARGV[2..-1]
end
