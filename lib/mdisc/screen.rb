require 'curses'

# The curses library only provides limit functions.
# Thus we need to add more wrapper functions based on curses.

class Screen
  def initialize(height = 25, width = 80)
    Curses.init_screen
    Curses.start_color
    Curses.cbreak
    Curses.stdscr.keypad(true)
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
    @draw.attrset color
    @draw.addstr(strip_invalid(string))
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

  def getstr
    @draw.getstr
  end

  def setpos(*args)
    @draw.setpos *args
  end

  private

  def strip_invalid(str)
    # Clean emoji.
    str = str.gsub(/[\u{00A9}\u{00AE}\u{203C}\u{2049}\u{2122}\u{2139}\u{2194}-\u{2199}\u{21A9}-\u{21AA}\u{231A}-\u{231B}\u{23E9}-\u{23EC}\u{23F0}\u{23F3}\u{24C2}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}\u{2600}-\u{2601}\u{260E}\u{2611}\u{2614}-\u{2615}\u{261D}\u{263A}\u{2648}-\u{2653}\u{2660}\u{2663}\u{2665}-\u{2666}\u{2668}\u{267B}\u{267F}\u{2693}\u{26A0}-\u{26A1}\u{26AA}-\u{26AB}\u{26BD}-\u{26BE}\u{26C4}-\u{26C5}\u{26CE}\u{26D4}\u{26EA}\u{26F2}-\u{26F3}\u{26F5}\u{26FA}\u{26FD}\u{2702}\u{2705}\u{2708}-\u{270C}\u{270F}\u{2712}\u{2714}\u{2716}\u{2728}\u{2733}-\u{2734}\u{2744}\u{2747}\u{274C}\u{274E}\u{2753}-\u{2755}\u{2757}\u{2764}\u{2795}-\u{2797}\u{27A1}\u{27B0}\u{27BF}\u{2934}-\u{2935}\u{2B05}-\u{2B07}\u{2B1B}-\u{2B1C}\u{2B50}\u{2B55}\u{3030}\u{303D}\u{3297}\u{3299}\u{1F004}\u{1F0CF}\u{1F170}-\u{1F171}\u{1F17E}-\u{1F17F}\u{1F18E}\u{1F191}-\u{1F19A}\u{1F201}-\u{1F202}\u{1F21A}\u{1F22F}\u{1F232}-\u{1F23A}\u{1F250}-\u{1F251}\u{1F300}-\u{1F31F}\u{1F330}-\u{1F335}\u{1F337}-\u{1F37C}\u{1F380}-\u{1F393}\u{1F3A0}-\u{1F3C4}\u{1F3C6}-\u{1F3CA}\u{1F3E0}-\u{1F3F0}\u{1F400}-\u{1F43E}\u{1F440}\u{1F442}-\u{1F4F7}\u{1F4F9}-\u{1F4FC}\u{1F500}-\u{1F507}\u{1F509}-\u{1F53D}\u{1F550}-\u{1F567}\u{1F5FB}-\u{1F640}\u{1F645}-\u{1F64F}\u{1F680}-\u{1F68A}\u{1F68C}-\u{1F6C5}]/, "").strip

    # Remove unnecessary charactors to prevent bad UI layout.
    # More info about regex and Unicode: http://www.regular-expressions.info/unicode.html
    str = str.gsub(/[\p{M}\p{Po}\p{So}]/, "").strip
  end
end
