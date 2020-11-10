# frozen_string_literal: true

require "termplot/window"
require "termplot/character_map"
require "termplot/colors"

module Termplot
  class Renderer
    def initialize(cols: 80, rows: 20, debug: false, widget_configs:)
      @window = Window.new(cols: cols, rows: rows)
      @widget_configs = widget_configs
      @debug = debug
      @errors = []
    end

    def render
      window.clear
      errors.clear

      position = [0, 0]
      widget_configs.each do |widget_config|
        widget_config.widget.render_to_window
        window.blit(
          widget_config.widget.window,
          widget_config.row,
          widget_config.col
        )
        @errors.concat(widget_config.widget.errors)
      end

      # Flush window to screen
      if debug?
        window.flush_debug.each do |row|
          print row
        end
      else
        rendered_string = window.flush
        print rendered_string
      end

      if errors.any?
        window.print_errors(errors)
      end
    end

    private
    attr_reader :cols, :rows, :widget_configs, :window, :errors

    def debug?
      @debug
    end
  end
end
