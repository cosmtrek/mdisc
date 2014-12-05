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

  PLAYER_X             = 6
  PLAYER_TITLE_Y       = 4
  PLAYER_STATUS_Y      = 5
  PLAYER_CONTENT_Y     = 7
  PLAYER_INFO_Y        = 17

  PLAYER_NOTE_X        = PLAYER_X - 2
  PLAYER_POINTER_X     = PLAYER_X - 3

  def initialize
    self.screen = Screen.new(SCREEN_HEIGHT, SCREEN_WIDTH)
    self.netease = NetEase.new
  end

  def build_playinfo(song_name, artist, pause = false)
    if pause
      screen.line(PLAYER_STATUS_Y, PLAYER_NOTE_X, 'S', 3)
    else
      screen.line(PLAYER_STATUS_Y, PLAYER_NOTE_X, 'P', 3)
    end

    sn = pretty(song_name, 0, 28)
    at = pretty(artist, 0, 24)
    info = "#{sn} - #{at}"
    screen.line(PLAYER_STATUS_Y, PLAYER_X, info, 4)
    screen.refresh
  end

  def build_loading
    screen.clear(PLAYER_CONTENT_Y, SCREEN_HEIGHT)
    screen.line(PLAYER_CONTENT_Y, PLAYER_X, 'loading...', 1)
    screen.refresh
  end

  def build_menu(datatype, title, datalist, offset, index, step)
    title = pretty(title, 0, 50)

    screen.clear(PLAYER_CONTENT_Y, SCREEN_HEIGHT)
    screen.line(PLAYER_TITLE_Y, PLAYER_X, title, 1)

    if datalist.size == 0
      screen.line(PLAYER_CONTENT_Y, PLAYER_X, '没有内容 Orz')
    else
      entries = offset...[datalist.length, offset + step].min

      case datatype
      when 'main'
        show(entries, index, offset, datalist) do |i, datalist|
          "#{i} #{datalist[i]}"
        end

        screen.line(PLAYER_INFO_Y, PLAYER_X, 'Crafted with <3 by cosmtrek', 3)

      when 'songs'
        show(entries, index, offset, datalist) do |i, datalist|
          sn = pretty(datalist[i]['song_name'], 0, 28)
          at = pretty(datalist[i]['artist'], 0, 24)
          "#{i} #{sn} - #{at}"
        end

      when 'artists'
        show(entries, index, offset, datalist) do |i, datalist|
          an = pretty(datalist[i]['artists_name'], 0, 28)
          "#{i} #{an}"
        end

      when 'albums'
        show(entries, index, offset, datalist) do |i, datalist|
          al = pretty(datalist[i]['albums_name'], 0, 28)
          an = pretty(datalist[i]['artists_name'], 0, 24)
          "#{i} #{al} - #{an}"
        end

      when 'playlists'
        show(entries, index, offset, datalist) do |i, datalist|
          pn = pretty(datalist[i]['playlists_name'], 0, 28);
          cn = pretty(datalist[i]['creator_name'], 0, 24);
          "#{i} #{pn}"
        end

      when 'djchannels'
        show(entries, index, offset, datalist) do |i, datalist|
          sn = pretty(datalist[i][0]['song_name'], 0, 28)
          "#{i} #{sn}"
        end

      when 'help'
        entries.each do |i|
          info = "#{i} #{datalist[i][0]} #{datalist[i][1]} #{datalist[i][2]}"
          screen.line(i-offset+PLAYER_CONTENT_Y, PLAYER_X, info)
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

    # If no results, then just return empty array.
    []
  end

  def build_favorite_menu
    screen.clear(PLAYER_CONTENT_Y, SCREEN_HEIGHT)
    screen.line(PLAYER_CONTENT_Y, PLAYER_X, '选择收藏条目类型：', 1)
    screen.line(PLAYER_CONTENT_Y + 1, PLAYER_X, '1 - 歌曲')
    screen.line(PLAYER_CONTENT_Y + 2, PLAYER_X, '2 - 精选歌单')
    screen.line(PLAYER_CONTENT_Y + 3, PLAYER_X, '3 - 专辑')
    screen.line(PLAYER_CONTENT_Y + 4, PLAYER_X, '4 - DJ 节目')
    screen.line(PLAYER_CONTENT_Y + 6, PLAYER_X, '请键入对应数字：', 2)
    screen.refresh
    screen.getch
  end

  def build_search_menu
    screen.clear(PLAYER_CONTENT_Y, SCREEN_HEIGHT)
    screen.line(PLAYER_CONTENT_Y, PLAYER_X, '选择搜索类型：', 1)
    screen.line(PLAYER_CONTENT_Y + 1, PLAYER_X, '1 - 歌曲')
    screen.line(PLAYER_CONTENT_Y + 2, PLAYER_X, '2 - 艺术家')
    screen.line(PLAYER_CONTENT_Y + 3, PLAYER_X, '3 - 专辑')
    screen.line(PLAYER_CONTENT_Y + 4, PLAYER_X, '4 - 精选歌单')
    screen.line(PLAYER_CONTENT_Y + 6, PLAYER_X, '请键入对应数字：', 2)
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
    screen.clear(PLAYER_CONTENT_Y, SCREEN_HEIGHT)
    screen.line(PLAYER_CONTENT_Y + 1, PLAYER_X, 'oh，出现错误 Orz', 2)
    screen.line(PLAYER_CONTENT_Y + 2, PLAYER_X, '1 - 再试一次')
    screen.line(PLAYER_CONTENT_Y + 3, PLAYER_X, '2 - 稍后再试')
    screen.line(PLAYER_CONTENT_Y + 5, PLAYER_X, '请键入对应数字：', 2)
    screen.refresh
    screen.getch
  end

  def get_param(prompt_str)
    screen.clear(PLAYER_CONTENT_Y, SCREEN_HEIGHT)
    screen.line(PLAYER_CONTENT_Y, PLAYER_X, prompt_str, 1)
    screen.setpos(PLAYER_CONTENT_Y + 2, PLAYER_X)
    params = screen.getstr
    if params.strip.nil?
      return get_param(prompt_str)
    else
      return params
    end
  end

  private

  def pretty(info, start, length)
    if info.size >= length
      "#{info[start, length]}..."
    else
      info
    end
  end

  def highlight_or_not(i, index, offset, info)
    if i == index
      highlight = "=> #{info}"
      screen.line(i-offset+PLAYER_CONTENT_Y, PLAYER_POINTER_X, highlight, 2)
    else
      screen.line(i-offset+PLAYER_CONTENT_Y, PLAYER_X, info)
    end
  end

  def show(entries, index, offset, datalist)
    entries.each do |i|
      info = yield(i, datalist) # Get custom info.
      highlight_or_not(i, index, offset, info)
    end
  end
end
