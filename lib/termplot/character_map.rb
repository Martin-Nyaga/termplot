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
      extended:   true
    }
    DEFAULT = LINE

    LINE_HEAVY = DEFAULT.merge(
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
      extended:   false
    }

    X = BASIC.merge(
      point: "x"
    )

    STAR = BASIC.merge(
      point: "*"
    )
  end
end
