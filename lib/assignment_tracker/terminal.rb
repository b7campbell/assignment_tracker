require_relative 'config.rb'

# ===================
# Terminal Interface
# ===================

class TerminalHelper
  def self.clear_terminal
    # http://stackoverflow.com/questions/2198377/how-to-clear-previous-output-in-terminal-in-mac-os-x 
    system('clear && printf \'\e[3J\'')
  end

  def self.redraw_terminal
    clear_terminal
    puts '=' * TERM_WIDTH
    puts ' ' * TERM_CENTER_POSITION + MENU_HEADER
  end

  def self.exit_routine
    sleep 0.5
    clear_terminal
  end

  def self.newline
    puts "\n"
  end

  def self.wait
    print 'Press return to continue: '
    gets
  end
end  

