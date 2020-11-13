require "forwardable"

module Termplot
  PositionedWidget = Struct.new(:row, :col, :widget, keyword_init: true) do
    extend Forwardable
    def_delegators :widget, :window, :errors, :render_to_window
  end
end
