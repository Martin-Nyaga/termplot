module Termplot
  module Commands
    def random
      "echo $RANDOM"
    end

    def memory
      "free | awk 'NR==2 { print ($3/$2) * 100 }'"
    end

    def cpu
      "top -b -n 1 | awk -F',' 'NR==3{ split($4, arr, \" \"); print 100.0 - arr[1] }'"
    end
  end

  module StdinCommands
    def sin(n)
      <<-CMD
        for i in $(seq #{n});
        do
          echo $i | awk '{ print sin($0/10)* 10; fflush("/dev/stdout") }';
          sleep 0.1;
        done
      CMD
    end
  end
end
