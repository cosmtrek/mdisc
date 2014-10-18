require 'curses'

# Player UI
#
# SCREEN_TOP, SCREEN_LEFT
# |-----|-------------SCREEN_WIDTH-----------------------|
# |  PLAYER_X                                            |
# |     |------------------------------------------------|
# |     |PLAYER_TITLE_Y                                  |
# |     |------------------------------------------------|
# |     |PLAYER_STATUS_Y                                 |
# |     |                                                |
# |     |------------------------------------------------|
# |     |PLAYER_CONTENT_Y                                |
# |     |                                                |
# |     |                                                |
# |     |                                                |SCREEN_HEIGHT
# |     |                                                |
# |     |                                                |
# |     |                                                |
# |     |                                                |
# |     |                                                |
# |     |                                                |
# |     |                                                |
# |     |------------------------------------------------|
# |     |PLAYER_INFO_Y                                   |
# |-----|------------------------------------------------|

class Ui
  attr_accessor :netease, :screen

  SCREEN_HEIGHT        = 40
  SCREEN_WIDTH         = 80
  SCREEN_TOP           = 0
  SCREEN_LEFT          = 0

  PLAYER_X             = 5
  PLAYER_TITLE_Y       = 4
  PLAYER_STATUS_Y      = 5
  PLAYER_CONTENT_Y     = 7
  PLAYER_INFO_Y        = 19

  PLAYER_NOTE_X        = PLAYER_X - 2
  PLAYER_POINTER_X     = PLAYER_X - 3

  def initialize
    Curses.init_screen
    Curses.start_color
    Curses.cbreak
    Curses.stdscr.keypad(true)
    Curses.init_pair(1, Curses::COLOR_BLUE, Curses::COLOR_BLACK)
    Curses.init_pair(2, Curses::COLOR_CYAN, Curses::COLOR_BLACK)
    Curses.init_pair(3, Curses::COLOR_RED, Curses::COLOR_BLACK)
    Curses.init_pair(4, Curses::COLOR_MAGENTA, Curses::COLOR_BLACK)

    # height, width, top, left
    self.screen = Curses::Window.new(SCREEN_HEIGHT, SCREEN_WIDTH, 0, 0)

    self.netease = NetEase.new
  end

  def build_playinfo(song_name, artist, pause = false)
    if pause
      putstr(screen, PLAYER_STATUS_Y, PLAYER_NOTE_X, '■', Curses.color_pair(3))
    else
      putstr(screen, PLAYER_STATUS_Y, PLAYER_NOTE_X, '▶', Curses.color_pair(3))
    end

    sn = pretty_format(song_name, 0, 32)
    at = pretty_format(artist, 0, 28)
    info = "#{sn} - #{at}"
    putstr(screen, PLAYER_STATUS_Y, PLAYER_X, info, Curses.color_pair(4))
    screen.refresh
  end

  def build_loading
    clear_to_bottom(screen, PLAYER_CONTENT_Y,SCREEN_HEIGHT)
    putstr(screen, PLAYER_CONTENT_Y, PLAYER_X, 'loading...', Curses.color_pair(1))
    screen.refresh
  end

  def build_menu(datatype, title, datalist, offset, index, step)
    title = pretty_format(title, 0, 52)

    clear_to_bottom(screen, PLAYER_CONTENT_Y,SCREEN_HEIGHT)
    putstr(screen, PLAYER_TITLE_Y, PLAYER_X, title, Curses.color_pair(1))

    if datalist.size == 0
      putstr(screen, PLAYER_CONTENT_Y, PLAYER_X, '没有内容 Orz')
    else
      case datatype
      when 'main'
        (offset...[datalist.length, offset + step].min).each do |i|
          if i == index
            info = "♩ #{i}. #{datalist[i]}"
            putstr(screen, i-offset+PLAYER_CONTENT_Y, PLAYER_POINTER_X, info, Curses.color_pair(2))
          else
            info = "#{i}. #{datalist[i]}"
            putstr(screen, i-offset+PLAYER_CONTENT_Y, PLAYER_X, info)
          end
        end

        putstr(screen, PLAYER_INFO_Y, PLAYER_X, 'Crafted with ❤ by cosmtrek', Curses.color_pair(3))

      when 'songs'
        (offset...[datalist.length, offset + step].min).each do |i|
          sn = pretty_format(datalist[i]['song_name'], 0, 32)
          at = pretty_format(datalist[i]['artist'], 0, 28)

          if i == index
            info = "♩ #{i}. #{sn} - #{at}"
            putstr(screen, i-offset+PLAYER_CONTENT_Y, PLAYER_POINTER_X, info, Curses.color_pair(2))
          else
            info = "#{i}. #{sn} - #{at}"
            putstr(screen, i-offset+PLAYER_CONTENT_Y, PLAYER_X, info)
          end
        end

      when 'artists'
        (offset...[datalist.length, offset + step].min).each do |i|
          an = pretty_format(datalist[i]['artists_name'], 0, 32)
          if i == index
            info = "♩ #{i}. #{an}"
            putstr(screen, i-offset+PLAYER_CONTENT_Y, PLAYER_POINTER_X, info, Curses.color_pair(2))
          else
            info = "#{i}. #{an}"
            putstr(screen, i-offset+PLAYER_CONTENT_Y, PLAYER_X, info)
          end
        end

      when 'albums'
        (offset...[datalist.length, offset + step].min).each do |i|
          al = pretty_format(datalist[i]['albums_name'], 0, 32)
          an = pretty_format(datalist[i]['artists_name'], 0, 28)
          if i == index
            info = "♩ #{i}. #{al} - #{an}"
            putstr(screen, i-offset+PLAYER_CONTENT_Y, PLAYER_POINTER_X, info, Curses.color_pair(2))
          else
            info = "#{i}. #{al} - #{an}"
            putstr(screen, i-offset+PLAYER_CONTENT_Y, PLAYER_X, info)
          end
        end

      when 'playlists'
        (offset...[datalist.length, offset + step].min).each do |i|
          pn = pretty_format(datalist[i]['playlists_name'], 0, 32);
          cn = pretty_format(datalist[i]['creator_name'], 0, 28);
          if i == index
            info = "♩ #{i}. #{pn} - #{cn}"
            putstr(screen, i-offset+PLAYER_CONTENT_Y, PLAYER_POINTER_X, info, Curses.color_pair(2))
          else
            info = "#{i}. #{pn} - #{cn}"
            putstr(screen, i-offset+PLAYER_CONTENT_Y, PLAYER_X, info)
          end
        end

      when 'djchannels'
        (offset...[datalist.length, offset + step].min).each do |i|
          sn = pretty_format(datalist[i][0]['song_name'], 0, 32)
          if i == index
            info = "♩ #{i}. #{sn}"
            putstr(screen, i-offset+PLAYER_CONTENT_Y, PLAYER_POINTER_X, info, Curses.color_pair(2))
          else
            info = "#{i}. #{sn}"
            putstr(screen, i-offset+PLAYER_CONTENT_Y, PLAYER_X, info)
          end
        end

      when 'help'
        (offset...[datalist.length, offset + step].min).each do |i|
          info = "#{i}. #{datalist[i][0]} #{datalist[i][1]} #{datalist[i][2]}"
          putstr(screen, i-offset+PLAYER_CONTENT_Y, PLAYER_X, info)
        end
      end
    end

  end

  def build_search(stype)
    case stype
    when 'songs'
      song_name = get_param('搜索歌曲：')
      data = netease.search(song_name, stype = 1)
      song_ids = []
      if data['result'].include? 'songs'
        if data['result']['songs'].include? 'mp3Url'
          songs = data['result']['songs']
        else
          (0...data['result']['songs'].size).each do |i|
            song_ids.push data['result']['songs'][i]['id']
          end
          songs = netease.songs_detail(song_ids)
        end
        return netease.dig_info(songs, 'songs')
      end

    when 'artists'
      artist_name = get_param('搜索艺术家：')
      data = netease.search(artist_name, stype = 100)
      if data['result'].include? 'artists'
        artists = data['result']['artists']
        return netease.dig_info(artists, 'artists')
      end

    when 'albums'
      artist_name = get_param('搜索专辑：')
      data = netease.search(artist_name, stype = 10)
      if data['result'].include? 'albums'
        albums = data['result']['albums']
        return netease.dig_info(albums, 'albums')
      end

    when 'playlists'
      artist_name = get_param('搜索精选歌单：')
      data = netease.search(artist_name, stype = 1000)
      if data['result'].include? 'playlists'
        playlists = data['result']['playlists']
        return netease.dig_info(playlists, 'playlists')
      end

    end
  end

  def build_favorite_menu
    clear_to_bottom(screen, PLAYER_CONTENT_Y,SCREEN_HEIGHT)
    putstr(screen, PLAYER_CONTENT_Y, PLAYER_X, '选择收藏条目类型：', Curses.color_pair(1))
    putstr(screen, PLAYER_CONTENT_Y + 1, PLAYER_X, '1 - 歌曲')
    putstr(screen, PLAYER_CONTENT_Y + 2, PLAYER_X, '2 - 精选歌单')
    putstr(screen, PLAYER_CONTENT_Y + 3, PLAYER_X, '3 - 专辑')
    putstr(screen, PLAYER_CONTENT_Y + 4, PLAYER_X, '4 - DJ 节目')
    putstr(screen, PLAYER_CONTENT_Y + 6, PLAYER_X, '请键入对应数字：', Curses.color_pair(2))
    screen.refresh
    screen.getch
  end

  def build_search_menu
    clear_to_bottom(screen, PLAYER_CONTENT_Y,SCREEN_HEIGHT)
    putstr(screen, PLAYER_CONTENT_Y, PLAYER_X, '选择搜索类型：', Curses.color_pair(1))
    putstr(screen, PLAYER_CONTENT_Y + 1, PLAYER_X, '1 - 歌曲')
    putstr(screen, PLAYER_CONTENT_Y + 2, PLAYER_X, '2 - 艺术家')
    putstr(screen, PLAYER_CONTENT_Y + 3, PLAYER_X, '3 - 专辑')
    putstr(screen, PLAYER_CONTENT_Y + 4, PLAYER_X, '4 - 精选歌单')
    putstr(screen, PLAYER_CONTENT_Y + 6, PLAYER_X, '请键入对应数字：', Curses.color_pair(2))
    screen.refresh
    screen.getch
  end

  def build_login
    params = get_param('请输入登录信息：(e.g. foobar@163.com foobar)')
    account = params.split(' ')
    return build_login if account.size != 2

    login_info = netease.login(account[0], account[1])
    if login_info['code'] != 200
      x = build_login_error
      return x == '1' ? build_login : -1
    else
      return [login_info, account]
    end
  end

  def build_login_error
    clear_to_bottom(screen, PLAYER_CONTENT_Y,SCREEN_HEIGHT)
    putstr(screen, PLAYER_CONTENT_Y + 1, PLAYER_X, 'oh，出现错误 Orz', Curses.color_pair(2))
    putstr(screen, PLAYER_CONTENT_Y + 2, PLAYER_X, '1 - 再试一次')
    putstr(screen, PLAYER_CONTENT_Y + 3, PLAYER_X, '2 - 稍后再试')
    putstr(screen, PLAYER_CONTENT_Y + 5, PLAYER_X, '请键入对应数字：', Curses.color_pair(2))
    screen.refresh
    screen.getch
  end

  def get_param(prompt_str)
    clear_to_bottom(screen, PLAYER_CONTENT_Y,SCREEN_HEIGHT)
    putstr(screen, PLAYER_CONTENT_Y, PLAYER_X, prompt_str, Curses.color_pair(1))
    screen.setpos(PLAYER_CONTENT_Y + 2, PLAYER_X)
    params = screen.getstr
    if params.strip.nil?
      return get_param(prompt_str)
    else
      return params
    end
  end

  private

  def putstr(screen, y, x, string, color = Curses.color_pair(0))
   screen.setpos(y, x)
   screen.clrtoeol
   screen.attrset(color)
   screen.addstr(string)
  end

  def clear_to_bottom(screen, top, bottom)
    (top..bottom).each do |i|
     screen.setpos(i, 0)
     screen.clrtoeol
    end
  end

  def pretty_format(info, start, length)
    if info.size >= length
      "#{info[start, length]}..."
    else
      info
    end
  end
end
