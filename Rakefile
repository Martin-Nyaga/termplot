require "bundler/gem_tasks"

namespace :test do
  task :bin do
    exec "ruby", "-Ilib", "bin/termplot", *ARGV[2..-1]
  end

  task :sin do
    cmd = <<-CMD
      for i in $(seq 5000);
      do
        echo $i | awk '{ print sin($0/10)* 10; fflush("/dev/stdout") }';
        sleep 0.1;
      done | ruby -Ilib bin/termplot -t 'sin(x)'
    CMD
    exec cmd
  end

  task :command do
    cmd = %( ruby -Ilib bin/termplot --command 'echo $RANDOM' --interval 900% )
    exec cmd
  end

  task :file do
    cmd = %( ruby -Ilib bin/termplot -f sample.rb )
    exec cmd 
  end
end
