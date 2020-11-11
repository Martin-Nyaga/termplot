module Termplot
  module CharacterMap
    LINE = {
      empty:      " ",
      point:      "─",
      vert_left:  "│",
      vert_right: "│",
      horz_top:   "─",
      horz_bot:   "─",
      bot_left:   "└",
      top_right:  "┐",
      top_left:   "┌",
      bot_right:  "┘",
      tick_right: "┤",
      extended:   true,
      filled:     false
    }
    DEFAULT = LINE

    HEAVY_LINE = DEFAULT.merge(
      point:      "━",
      vert_left:  "┃",
      vert_right: "┃",
      horz_top:   "━",
      horz_bot:   "━",
      bot_left:   "┗",
      top_right:  "┓",
      top_left:   "┏",
      bot_right:  "┛",
      tick_right: "┫"
    )

    BASIC = {
      empty:      " ",
      point:      "•",
      extended:   false,
      filled:     false
    }
    DOTS = BASIC

    X = BASIC.merge(
      point: "x"
    )

    STAR = BASIC.merge(
      point: "*"
    )

    BAR = LINE.merge(
      point: "▄",
      extended: false,
      filled: true
    )

    LINE_STYLES = {
      "line"       => LINE,
      "heavy-line" => HEAVY_LINE,
      "dot"        => DOTS,
      "star"       => STAR,
      "x"          => X,
      "bar"        => BAR,
    }
  end
end
