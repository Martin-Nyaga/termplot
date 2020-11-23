require "io/console"

module Termplot
  class Shell
    class << self
      attr_reader :termios_settings

      CURSOR_HIDE = "\e[?25l"
      CURSOR_SHOW = "\e[?25h"
      CLEAR_SCREEN = "\e[2J"

      def init(clear: false)
        print CLEAR_SCREEN if clear

        # Disable echo on stdout tty, prevents printing chars if you type in
        STDOUT.echo = false

        print CURSOR_HIDE
        at_exit { reset }
        Signal.trap("INT") { exit(0) }
      end

      # Leave a 1 char buffer on the right/bottom
      def get_dimensions
        STDOUT.winsize.map { |d| d - 1 }
      end

      def reset
        STDOUT.echo = true

        print CURSOR_SHOW
      end
    end
  end
end
