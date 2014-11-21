require 'curses'

# The curses library only provides limit functions.
# Thus we need to add more wrapper functions based on curses.

class Screen
  def initialize(height = 25, width = 80)
    Curses.init_screen
    Curses.start_color
    Curses.cbreak
    Curses.stdscr.keypad true
    Curses.init_pair(1, Curses::COLOR_BLUE, Curses::COLOR_BLACK)
    Curses.init_pair(2, Curses::COLOR_CYAN, Curses::COLOR_BLACK)
    Curses.init_pair(3, Curses::COLOR_RED, Curses::COLOR_BLACK)
    Curses.init_pair(4, Curses::COLOR_MAGENTA, Curses::COLOR_BLACK)
    # height, width, top, left
    @draw = Curses::Window.new(height, width, 0, 0)
  end

  def line(y, x, string, num = 0)
    color = Curses.color_pair num
    @draw.setpos(y, x)
    @draw.clrtoeol
    @draw.attrset(color)
    @draw.addstr(string)
  end

  def clear(top, bottom)
    (top..bottom).each do |i|
      @draw.setpos(i, 0)
      @draw.clrtoeol
    end
  end

  def refresh
    @draw.refresh
  end

  def getch
    @draw.getch
  end

  def setpos(*args)
    @draw.setpos *args
  end
end
