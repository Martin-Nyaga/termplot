require "termplot/commands"
require "termplot/dsl/widgets"

module Termplot
  module DSL
    class Panel
      include Termplot::Commands
      include Termplot::WidgetDSL

      attr_accessor(
        :rows,
        :cols,
        :start_row,
        :start_col
      )

      def initialize(options, children = [])
        @options = options
        @children = children
      end

      def set_dimensions(rows, cols, start_row, start_col)
        raise "Must be implemented"
      end

      def flatten
        children.map(&:flatten).flatten
      end

      private
      attr_reader :options, :children

      def row(&block)
        new_row = Row.new(options)
        new_row.instance_eval(&block)
        children.push(new_row)
      end

      def col(&block)
        new_col = Col.new(options)
        new_col.instance_eval(&block)
        children.push(new_col)
      end
    end

    class Row < Panel
      def set_dimensions(rows, cols, start_row, start_col)
        @rows = rows
        @cols = cols
        child_cols = cols / children.count

        children.each_with_index do |child, index|
          child.set_dimensions(
            rows,
            child_cols,
            start_row,
            child_cols * index
          )
        end
      end
    end

    class Col < Panel
      def set_dimensions(rows, cols, start_row, start_col)
        @rows = rows
        @cols = cols
        child_rows = rows / children.count

        children.each_with_index do |child, index|
          child.set_dimensions(
            child_rows,
            cols,
            child_rows * index,
            start_col
          )
        end
      end
    end
  end
end
