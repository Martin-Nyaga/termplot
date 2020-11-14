require "termios"

module Termplot
  class Shell
    class << self
      attr_reader :termios_settings

      CURSOR_HIDE = "\e[?25l"
      CURSOR_SHOW = "\e[?25h"
      CLEAR_SCREEN = "\e[2J"
      # TODO: Maybe clear?
      def init(clear: false)
        print CLEAR_SCREEN if clear
        # Disable echo on stdout tty, prevents printing chars if you type in
        # between rendering
        @termios_settings = Termios.tcgetattr($stdout)
        new_termios_settings = termios_settings.dup
        new_termios_settings.c_lflag &= ~(Termios::ECHO)
        Termios.tcsetattr($stdout, Termios::TCSAFLUSH, new_termios_settings)

        print CURSOR_HIDE
        at_exit { reset }
        Signal.trap("INT") { exit(0) }
      end

      def get_dimensions
        `stty size`.scan(/\d+/).map(&:to_i)
      end

      def reset
        # Reset stdout tty to original settings
        Termios.tcsetattr($stdout, Termios::TCSAFLUSH, termios_settings)

        print CURSOR_SHOW
      end
    end
  end
end
