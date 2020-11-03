require "termplot/cursors/virtual_cursor"
require "termplot/cursors/control_chars"

module Termplot
  class ConsoleCursor < VirtualCursor
    include Termplot::ControlChars

    def write(char)
      if writeable?
        print(char)
        super(char)
      end
    end

    def forward(n = 1)
      moved = super(n)
      moved.times { print FORWARD }
    end

    def back(n = 1)
      moved = super(n)
      moved.times { print BACK }
    end

    def up(n=1)
      moved = super(n)
      moved.times { print UP }
    end

    def down(n=1)
      moved = super(n)
      moved.times { print DOWN }
    end

    def beginning_of_line
      super
      print CR
    end

    def new_line
      print NEWLINE
    end

    def position=()
      raise "Cannot set cursor position directly"
    end

    def row=()
      raise "Cannot set cursor position directly"
    end

    def col=()
      raise "Cannot set cursor position directly"
    end
  end
end
