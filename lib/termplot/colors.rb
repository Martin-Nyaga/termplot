module Termplot
  class Colors
    COLORS = {
      black:         0,
      light_black:   60,
      red:           1,
      light_red:     61,
      green:         2,
      light_green:   62,
      yellow:        3,
      light_yellow:  63,
      blue:          4,
      light_blue:    64,
      magenta:       5,
      light_magenta: 65,
      cyan:          6,
      light_cyan:    66,
      white:         7,
      light_white:   67,
      default:       9
    }

    MODES = {
      default:   0,
      bold:      1,
      italic:    3,
      underline: 4,
      blink:     5,
      swap:      7,
      hide:      8
    }

    class << self
      COLORS.each do |(color, code)|
        define_method(color) do |str|
          escape_color(color) + str + escape_mode(:default)
        end
        define_method("#{color}_bg") do |str|
          escape_bg_color(color) + str + escape_mode(:default)
        end
      end

      def fetch(color, default)
        COLORS.key?(color.to_sym) ? color.to_sym : default.to_sym
      end

      private

      def escape_color(color)
        "\e[#{COLORS[color] + 30}m"
      end

      def escape_bg_color(color)
        "\e[#{COLORS[color] + 40}m"
      end

      def escape_mode(mode)
        "\e[#{MODES[mode]}m"
      end
    end
  end
end
