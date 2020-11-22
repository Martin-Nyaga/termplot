# frozen_string_literal: true

require "termplot/dsl/panels"

module Termplot
  class FileConfig
    attr_reader :options, :rows, :cols, :widget_configs
    def initialize(options)
      @options = options
      @path = options.file
      @rows = options.rows
      @cols = options.cols
      @widget_configs = nil
    end

    def parse_config
      code = File.read(path)
      top_level_panel = Termplot::DSL::Col.new(options)
      top_level_panel.instance_eval(code)

      @widget_configs = resolve_widget_positions(top_level_panel)
      self
    end

    def positioned_widgets
      widget_configs.map(&:positioned_widget)
    end

    private
    attr_reader :path

    def resolve_widget_positions(top_level_panel)
      top_level_panel.set_dimensions(rows, cols, 0, 0)
      top_level_panel.flatten
    end
  end
end
