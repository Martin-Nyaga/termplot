col do
  row do
    cpu_command = "top -b -n 1 | awk -F',' 'NR==3{ split($4, arr, \" \"); print 100.0 - arr[1] }'"

    histogram  title: "CPU (%)", command: cpu_command, color: "light_cyan"
    timeseries title: "CPU (%)", command: cpu_command, color: "light_cyan"
    statistics title: "CPU (%)", command: cpu_command
  end

  row do
    memory_command = "free | awk 'NR==2 { print ($3/$2) * 100 }'"

    histogram  title: "Memory (%)", command: memory_command, color: "light_magenta"
    timeseries title: "Memory (%)", command: memory_command, color: "light_magenta"
    statistics title: "Memory (%)", command: memory_command
  end
end
