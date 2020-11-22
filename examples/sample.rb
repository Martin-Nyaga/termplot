cpu_command = "top -b -n 1 | awk -F',' 'NR==3{ split($4, arr, \" \"); print 100.0 - arr[1] }'"

row do
  col do
    timeseries title: "CPU (%)",
      line_style: "bar",
      color: "green",
      command: cpu_command

    timeseries title: "Memory Use (%)",
      line_style: "bar",
      color: "yellow",
      command: "free | awk 'NR==2 { print ($3/$2) * 100 }'"

    statistics title: "CPU (%) Stats", command:  cpu_command
  end

  col do
    histogram title: "Random",
              command: "echo $RANDOM | awk '{ print $0 / 10 }'",
              interval: 1000

    timeseries title: "GOOG",
      line_style: "heavy-line",
      color: "yellow",
      command: "NO_COLOR=1 ticker.sh GOOG | awk '{ print $2 }'",
      interval: 10000

    timeseries title: "Random",
      line_style: "heavy-line",
      color: "white",
      command: random
  end
end
