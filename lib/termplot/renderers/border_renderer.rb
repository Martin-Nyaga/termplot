require "termplot/character_map"

module Termplot
  module Renderers
    class BorderRenderer
      attr_reader(
        :window,
        :border_char_map
      )

      def initialize(
        bordered_window:,
        border_char_map: CharacterMap::DEFAULT
      )

        @window = bordered_window
        @border_char_map = border_char_map
      end

      def render
        window.cursor.reset_position

        # Top Border
        window.cursor.down(window.border_size.top - 1)
        window.cursor.forward(window.border_size.left - 1)
        window.write(border_char_map[:top_left])
        window.inner_width.times { window.write(border_char_map[:horz_top]) }
        window.write(border_char_map[:top_right])
        window.cursor.forward(window.border_size.right - 1)

        # Left and right borders
        window.inner_height.times do |y|
          window.cursor.forward(window.border_size.left - 1)
          window.write(border_char_map[:vert_right])
          window.cursor.forward(window.inner_width)
          window.write(border_char_map[:vert_left])
          window.cursor.forward(window.border_size.right - 1)
        end

        # Bottom border
        window.cursor.forward(window.border_size.left - 1)
        window.write(border_char_map[:bot_left])
        window.inner_width.times { window.write(border_char_map[:horz_top]) }
        window.write(border_char_map[:bot_right])
      end
    end
  end
end
