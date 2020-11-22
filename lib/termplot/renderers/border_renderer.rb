require "termplot/character_map"

module Termplot
  module Renderers
    class BorderRenderer
      attr_reader(
        :window,
        :border_size,
        :inner_width,
        :inner_height,
        :border_char_map
      )

      def initialize(
        window:,
        border_size:,
        inner_width:,
        inner_height:,
        border_char_map: CharacterMap::DEFAULT
      )

        @window = window
        @border_size = border_size
        @inner_width = inner_width
        @inner_height = inner_height
        @border_char_map = border_char_map
      end

      # Render borders defined by border_size at the edges of the given window
      def render
        window.cursor.reset_position

        window.cursor.down(border_size.top - 1)
        window.cursor.forward(border_size.left - 1)
        window.write(border_char_map[:top_left])
        inner_width.times { window.write(border_char_map[:horz_top]) }
        window.write(border_char_map[:top_right])
        window.cursor.forward(border_size.right - 1)

        inner_height.times do |y|
          window.cursor.forward(border_size.left - 1)
          window.write(border_char_map[:vert_right])
          window.cursor.forward(inner_width)
          window.write(border_char_map[:vert_left])
          window.cursor.forward(border_size.right - 1)
        end

        # Bottom border
        # Jump to bottom left corner
        window.cursor.forward(border_size.left - 1)
        window.write(border_char_map[:bot_left])
        inner_width.times { window.write(border_char_map[:horz_top]) }
        window.write(border_char_map[:bot_right])
      end
    end
  end
end
