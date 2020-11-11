module Termplot
  module Renderable
    # Included in any module that has the ivars:
    #   :window
    #   :errors
    #   :debug
    # And methods:
    #   #render_tO_window
    # Provides rendering to string and stdout
    def render
      rendered_string = render_to_string
      if debug?
        rendered_string.each do |row|
          print row
        end
      else
        print rendered_string
        STDOUT.flush
      end

      if errors.any?
        window.print_errors(errors)
      end
    end

    def render_to_string
      render_to_window
      debug? ? window.flush_debug : window.flush
    end

    def debug?
      @debug
    end
  end
end
