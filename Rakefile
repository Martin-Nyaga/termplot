require "bundler/gem_tasks"

task :bin do
  Bundler.require(:default)
  exec "bin/termplot", *ARGV[2..-1]
end

task :sin_test do
  cmd = <<-CMD
    for i in $(seq 5000);
    do
      echo $i | awk '{ print sin($0/10)* 10; fflush("/dev/stdout") }';
      sleep 0.1;
    done | ruby -Ilib bin/termplot -- -t 'sin(x)'
  CMD
  exec cmd
end

