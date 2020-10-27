CLEAR_LINE = "\e[K"
LINE_BEGIN = "\r"
CURSOR_UP = "\e[A"
CURSOR_DOWN = "\e[B"
$drawn = false

def clear(window)
  window.each {|_| print CURSOR_DOWN }
  window.each {|_| print LINE_BEGIN; print CLEAR_LINE; print CURSOR_UP }
end

def draw(arr, window)
  arr.each_with_index do |v, i|
    window[window.size-1-v][i] = v
  end

  render(window)
  $drawn = true
end

def render(window)
  clear(window) if $drawn
  window.each do |line|
    line.each do |v|
      if v.nil?
        print " "
      else
        print "+"
      end
    end
    puts
  end
end

data = []
window = Array.new(10) { Array.new(50) { nil } }

while n = gets&.chomp do
  data.push(n.to_i)
  draw(data, window)
end

