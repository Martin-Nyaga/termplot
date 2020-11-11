# frozen_string_literal: true

require "termplot/window"
require "termplot/character_map"
require "termplot/colors"
require "termplot/renderable"

module Termplot
  class Renderer
    include Renderable

    def initialize(cols: 80, rows: 20, debug: false, widgets:)
      @window = Window.new(cols: cols, rows: rows)
      @widgets = widgets
      @debug = debug
      @errors = []
    end

    def render_to_window
      window.clear
      errors.clear

      position = [0, 0]
      widgets.each do |widget|
        widget.render_to_window
        window.blit(
          widget.window,
          widget.row,
          widget.col
        )
        @errors.concat(widget.errors)
      end
    end

    private
    attr_reader :cols, :rows, :widgets, :window, :errors
  end
end
