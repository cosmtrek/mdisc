require 'curses'
require 'json'

SHORTCUT =  [
  ['j', 'Down        ', '向下'],
  ['k', 'Up          ', '向上'],
  ['h', 'Back        ', '后退'],
  ['l', 'Forward     ', '前进或播放高亮选中歌曲'],
  ['[', 'Prev song   ', '上一首歌曲'],
  [']', 'Next song   ', '下一首歌曲'],
  [' ', 'Play / Pause', '播放 / 暂停当前进行的歌曲'],
  ['u', 'Prev page   ', '上一页列表'],
  ['d', 'Next page   ', '下一页列表'],
  ['f', 'Search      ', '搜索'],
  ['m', 'Menu        ', '主菜单'],
  ['p', 'Present     ', '当前播放列表'],
  ['s', 'Star        ', '收藏歌曲、精选歌单、专辑'],
  ['t', 'Playlist    ', '收藏精选歌单'],
  ['c', 'Collection  ', '收藏歌曲列表'],
  ['a', 'Album       ', '收藏专辑'],
  ['z', 'DJ Channels ', '收藏 DJ 节目'],
  ['r', 'Remove      ', '删除当前曲目'],
  ['q', 'Quit        ', '退出']
]

class Menu
  def initialize
    self.player = Player.new
    self.ui = Ui.new
    self.netease = NetEase.new
    self.screen = ui.screen
    @datatype = 'main'
    @title = '网易云音乐'
    @datalist = %w(排行榜 精选歌单 艺术家 新碟上架 我的歌单 DJ节目 本地收藏 搜索 帮助)
    @offset = 0
    @index = 0
    @present_songs = []
    @step = 10
    @stack = []
    @userid = nil
    @username = nil
    @collection = []
    @playlists = []
    @account = {}

    @wait = 0.1
    @carousel = ->(left, right, x){x < left ? right : (x > right ? left : x)}

    read_data
  end

  def start
    ui.build_menu(@datatype, @title, @datalist, @offset, @index, @step)
    @stack.push([@datatype, @title, @datalist, @offset, @index, @step])

    loop do
      datatype = @datatype
      title = @title
      datalist = @datalist
      offset = @offset
      idx = index = @index
      step = @step
      stack = @stack
      key = @screen.getch
      screen.refresh

      case key

      # Quit
      when 'q'
        break

      # Up
      when 'k'
        @index = @carousel[@offset, [datalist.size, offset+step].min - 1, idx - 1]

      # Down
      when 'j'
        @index = @carousel[@offset, [datalist.size, offset+step].min - 1, idx + 1]

      # Previous page
      when 'u'
        next if offset == 0
        @offset = @offset - step
        @index = (index - step).divmod(step)[0] * step

      # Next page
      when 'd'
        next if offset + step >= datalist.size
        @offset = @offset + step
        @index = (index + step).divmod(step)[0] * step

      # Forward
      when 'l'
        next if @datatype == 'help'
        if @datatype == 'songs' || @datatype == 'djchannels'
          player.play(@datatype, datalist, @index, true)
          @present_songs = [datatype, title, datalist, offset, index]
        else
          ui.build_loading
          dispatch_enter(idx)
          @index = 0
          @offset = 0
        end

      # Back
      when 'h'
        next if @stack.size == 1
        up = stack.pop
        @datatype, @title, @datalist, @offset, @index = up[0], up[1], up[2], up[3], up[4]

      # Search
      when 'f'
        search

      # Next song
      when ']'
        player.next
        sleep @wait

      # Previous song
      when '['
        player.prev
        sleep @wait

      # Play or pause a song.
      when ' '
        player.play(datatype, datalist, idx)
        sleep @wait

      # Load present playlist.
      when 'p'
        next if @present_songs.empty?
        @stack.push([datatype, title, datalist, offset, index])
        @datatype, @title, @datalist, @offset, @index = @present_songs[0], @present_songs[1], @present_songs[2], @present_songs[3], @present_songs[4]

      # Star a song, a playlist or an album.
      when 's'
        next if datalist.empty?
        if datatype == 'songs'
          @collection.push(datalist[idx]).uniq!
        elsif datatype == 'playlists'
          @playlists.push(datalist[idx]).uniq!
        elsif datatype == 'albums'
          @albums.push(datalist[idx]).uniq!
        elsif datatype == 'djchannels'
          @djs.push(datalist[idx]).uniq!
        end

      # Load favorite playlists.
      when 't'
        @stack.push([datatype, title, datalist, offset, index])
        @datatype = 'playlists'
        @title = '网易云音乐 > 收藏精选歌单'
        @datalist = @playlists
        @offset = 0
        @index = 0

      # Load favorite songs.
      when 'c'
        @stack.push([datatype, title, datalist, offset, index])
        @datatype = 'songs'
        @title = '网易云音乐 > 收藏歌曲列表'
        @datalist = @collection
        @offset = 0
        @index = 0

      # Load favorite albums
      when 'a'
        @stack.push([datatype, title, datalist, offset, index])
        @datatype = 'albums'
        @title = '网易云音乐 > 收藏专辑'
        @datalist = @albums
        @offset = 0
        @index = 0

      # Load favorite dj channels
      when 'z'
        @stack.push([datatype, title, datalist, offset, index])
        @datatype = 'djchannels'
        @title = '网易云音乐 > 收藏 DJ 节目'
        @datalist = @djs
        @offset = 0
        @index = 0

      # Remove an entry from the present list.
      when 'r'
        if (datatype != 'main') && !datalist.empty?
          @datalist.delete_at(idx)
          @index = @carousel[@offset, [datalist.size, offset+step].min - 1, idx]
        end

      # Main menu.
      when 'm'
        if datatype != 'main'
          @stack.push([datatype, title, datalist, offset, index])
          @datatype, @title, @datalist = @stack[0][0], @stack[0][1], @stack[0][2]
          @offset = 0
          @index = 0
        end

      end

      write_data
      ui.build_menu(@datatype, @title, @datalist, @offset, @index, @step)
    end

    player.stop
    exit
  end

  def dispatch_enter(idx)
    # netease = @netease
    datatype = @datatype
    title = @title
    datalist = @datalist
    offset = @offset
    index = @index
    @stack.push([datatype, title, datalist, offset, index])

    case datatype
    when 'main'
      choice_channel idx

    # Hot songs to which a artist belongs.
    when 'artists'
      artist_id = datalist[idx]['artist_id']
      songs = netease.artists(artist_id)
      @datatype = 'songs'
      @datalist = netease.dig_info(songs, 'songs')
      @title += " > #{datalist[idx]['aritsts_name']}"

    # All songs to which an album belongs.
    when 'albums'
      album_id = datalist[idx]['album_id']
      songs = netease.album(album_id)
      @datatype = 'songs'
      @datalist = netease.dig_info(songs, 'songs')
      @title += " > #{datalist[idx]['albums_name']}"

    # All songs to which a playlist belongs.
    when 'playlists'
      playlist_id = datalist[idx]['playlist_id']
      songs = netease.playlist_detail(playlist_id)
      @datatype = 'songs'
      @datalist = netease.dig_info(songs, 'songs')
      @title += " > #{datalist[idx]['playlists_name']}"
    end
  end

  def choice_channel(idx)
    # netease = @netease

    case idx

    # Top
    when 0
      songs = netease.top_songlist
      @datalist = netease.dig_info(songs, 'songs')
      @title += ' > 排行榜'
      @datatype = 'songs'

    # Playlists
    when 1
      playlists = netease.top_playlists
      @datalist = netease.dig_info(playlists, 'playlists')
      @title += ' > 精选歌单'
      @datatype = 'playlists'

    # Artist
    when 2
      artists = netease.top_artists
      @datalist = netease.dig_info(artists, 'artists')
      @title += ' > 艺术家'
      @datatype = 'artists'

    # New album
    when 3
      albums = netease.new_albums
      @datalist = netease.dig_info(albums, 'albums')
      @title += ' > 新碟上架'
      @datatype = 'albums'

    # My playlist
    when 4
      # Require user's account before fetching his playlists.
      if !@userid
        user_info = netease.login(@account[0], @account[1]) unless @account.empty?

        if @account == {} || user_info['code'] != 200
          data = ui.build_login
          return if data == -1
          user_info, @account = data[0], data[1]
        end

        @username = user_info['profile']['nickname']
        @userid = user_info['account']['id']
      end

      # Fetch this user's all playlists while he logs in successfully.
      my_playlist = netease.user_playlists(@userid)
      @datalist = netease.dig_info(my_playlist, 'playlists')
      @datatype = 'playlists'
      @title += " > #{@username} 的歌单"

    # DJ channels
    when 5
      @datatype = 'djchannels'
      @title += ' > DJ 节目'
      @datalist = netease.djchannels

    # Favorite things.
    when 6
      favorite

    # Search
    when 7
      search

    # Help
    when 8
      @datatype = 'help'
      @title += ' > 帮助'
      @datalist = SHORTCUT
    end

    @offset = 0
    @index = 0
  end

  def favorite
    # ui = @ui
    x = ui.build_favorite_menu

    if (1..4).include? x.to_i
      @stack.push([@datatype, @title, @datalist, @offset, @index])
      @index = 0
      @offset = 0
    end

    case x

    when '1'
      @datatype = 'songs'
      @datalist = @collection
      @title += ' > 收藏歌曲'

    when '2'
      @datatype = 'playlists'
      @datalist = @playlists
      @title += ' > 收藏歌单'

    when '3'
      @datatype = 'albums'
      @datalist = @albums
      @title += ' > 收藏专辑'

    when '4'
      @datatype = 'djchannels'
      @datalist = @djs
      @title += ' > 收藏 DJ 节目'

    end
  end

  def search
    # ui = @ui
    x = ui.build_search_menu

    if (1..4).include? x.to_i
      @stack.push([@datatype, @title, @datalist, @offset, @index])
      @index = 0
      @offset = 0
    end

    case x

    when '1'
      @datatype = 'songs'
      @datalist = ui.build_search('songs')
      @title = '歌曲搜索列表'

    when '2'
      @datatype = 'artists'
      @datalist = ui.build_search('artists')
      @title = '艺术家搜索列表'

    when '3'
      @datatype = 'albums'
      @datalist = ui.build_search('albums')
      @title = '专辑搜索列表'

    when '4'
      @datatype = 'playlists'
      @datalist = ui.build_search('playlists')
      @title = '精选歌单搜索列表'
    end
  end

  private

  def check_mdisc_dir
    Dir.mkdir File.expand_path("~/.mdisc") unless Dir.exist? File.expand_path("~/.mdisc")
  end

  def read_data
    check_mdisc_dir
    user_file = File.expand_path("~/.mdisc/flavor.json")
    return unless File.exist? user_file

    data = JSON.parse(File.read(user_file))
    @account = data['account'] || {}
    @collection = data['collection'] || []
    @playlists = data['playlists'] || []
    @albums = data['albums'] || []
    @djs = data['djs'] || []
  end

  def write_data
    user_file = File.expand_path("~/.mdisc/flavor.json")
    data = {
      :account => @account,
      :collection => @collection,
      :playlists => @playlists,
      :albums => @albums,
      :djs => @djs
    }

    File.open(user_file, 'w') do |f|
      f.write(JSON.generate(data))
    end
  end
end
