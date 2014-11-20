require 'unirest'
require 'json'
require 'digest'

class NetEase
  TIMEOUT = 10

  def initialize
    @header = {
      "Accept"          => "*/*",
      "Accept-Encoding" => "gzip,deflate,sdch",
      "Accept-Language" => "zh-CN,zh;q=0.8,gl;q=0.6,zh-TW;q=0.4",
      "Connection"      => "keep-alive",
      "Content-Type"    => "application/x-www-form-urlencoded",
      "Host"            => "music.163.com",
      "Referer"         => "http://music.163.com/",
      "User-Agent"      => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.152 Safari/537.36"
    }

    Unirest.timeout TIMEOUT
  end

  # Log in
  def login(username, password)
    action = 'http://music.163.com/api/login/'
    query = {
      "username" => username,
      "password" => Digest::MD5.hexdigest(password),
      "rememberLogin" => "true"
    }

    http_request('POST', action, query)
  rescue => e
    {"code" => 501}
  end

  # User's playlists
  def user_playlists(uid, offset = 0, limit = 100)
    action = "http://music.163.com/api/user/playlist/?offset=#{offset}&limit=#{limit}&uid=#{uid}"
    data = http_request('GET', action)

    data['playlist']
  end

  # Search song(1)，artist(100)，album(10)，playlist(1000)，user(1002)
  def search(s, stype = 1, offset = 0, limit = 100)
    action = 'http://music.163.com/api/search/get/web'
    query = {
      "s" => s,
      "type" => stype,
      "offset" => offset,
      "total" => true,
      "limit" => limit
    }

    http_request('POST', action, query)
  end

  # New albums
  # http://music.163.com/#/discover/album/
  def new_albums(offset=0, limit=50)
    action = "http://music.163.com/api/album/new?area=ALL&offset=#{offset}&total=true&limit=#{limit}"
    data = http_request('GET', action)

    data['albums']
  end

  # Top playlists
  # hot||new http://music.163.com/#/discover/playlist/
  # '全部' => '%E5%85%A8%E9%83%A8'
  def top_playlists(category = '%E5%85%A8%E9%83%A8', order = 'hot', offset = 0, limit = 100)
    flag = offset > 0 ? true : false
    action = "http://music.163.com/api/playlist/list?cat=#{category}&order=#{order}&offset=#{offset}&total=#{flag}&limit=#{limit}"
    data = http_request('GET', action)

    data['playlists']
  end

  # Playlist's details
  def playlist_detail(playlist_id)
    action = "http://music.163.com/api/playlist/detail?id=#{playlist_id}"
    data = http_request('GET', action)

    data['result']['tracks']
  end

  # Top artists
  # http://music.163.com/#/discover/artist/
  def top_artists(offset = 0, limit = 100)
    action = "http://music.163.com/api/artist/top?offset=#{offset}&total=false&limit=#{limit}"
    data = http_request('GET', action)

    data['artists']
  end

  # Top songlist
  # http://music.163.com/#/discover/toplist 100
  def top_songlist
    action = 'http://music.163.com/discover/toplist'
    connection = http_request('GET', action)
    songids = connection.scan(/\/song\?id=(\d+)/).uniq

    songs_detail songids
  end

  # Songs to which a artist belongs.
  def artists(artist_id)
    action = "http://music.163.com/api/artist/#{artist_id}"
    data = http_request('GET', action)

    data['hotSongs']
  end

  # album id -> song id set
  def album(album_id)
    action = "http://music.163.com/api/album/#{album_id}"
    data = http_request('GET', action)

    data['album']['songs']
  end

  # song ids -> song urls (details)
  def songs_detail(ids, offset = 0)
    return [] if ids.empty?

    tmpids = ids[offset, 100]
    action = "http://music.163.com/api/song/detail?ids=[#{tmpids.join(',')}]"
    data = http_request('GET', action)

    data['songs']
  end

  # song id -> song url (details)
  def song_detail(song_id)
    id = song_id.join(',')
    action = "http://music.163.com/api/song/detail/?id=#{id}&ids=[#{id}]"
    data = http_request('GET', action)

    data['songs']
  end

  # DJ channels: hot today(0), week(10), history(20), new(30)
  def djchannels(stype = 0, offset = 0, limit = 50)
    action = "http://music.163.com/discover/djchannel?type=#{stype}&offset=#{offset}&limit=#{limit}"
    connection = http_request('GET', action)
    channelids = connection.scan(/\/dj\?id=(\d+)/).uniq || []

    channel_detail channelids
  end

  # DJchannel (id, channel_name) ids -> song urls (details)
  # channels -> songs
  def channel_detail(channelids)
    return [] if channelids.empty?

    channels = []

    # ["xxxxxx"] -> "xxxxxx"
    channelids.each do |c|
      action = "http://music.163.com/api/dj/program/detail?id=#{c.join('')}"
      begin
        data = http_request('GET', action)
        channel = dig_info(data['program']['mainSong'], 'channels')
        channels.push channel
      rescue => e
        next
      end
    end

    channels
  end

  def dig_info(data, dig_type)
    tmp = []

    case dig_type
    when 'songs'
      data.each do |song|
        song_info = {
          "song_id" => song['id'],
          "artist" => [],
          "song_name" => song['name'],
          "album_name" => song['album']['name'],
          "mp3_url" => song['mp3Url']
        }

        if song.include? 'artist'
          song_info['artist'] = song['artist'].join('')
        elsif song.include? 'artists'
          song['artists'].each do |artist|
            song_info['artist'].push artist['name'].strip
          end
        else
          song_info['artist'] = '未知艺术家'
        end

        song_info['artist'] = song_info['artist'].join(',')
        tmp.push song_info
      end

    when 'artists'
      data.each do |artist|
        artists_info = {
          "artist_id" => artist['id'],
          "artists_name" => artist['name'],
          "alias" => artist['alias'].join('')
        }
        tmp.push artists_info
      end

    when 'albums'
      data.each do |album|
        albums_info = {
          "album_id" => album['id'],
          "albums_name" => album['name'],
          "artists_name" => album['artist']['name']
        }
        tmp.push albums_info
      end

    when 'playlists'
      data.each do |playlist|
        playlists_info = {
          "playlist_id" => playlist['id'],
          "playlists_name" => playlist['name'],
          "creator_name" => playlist['creator']['nickname']
        }
        tmp.push playlists_info
      end

    when 'channels'
      channel_info = {
        "song_id" => data['id'],
        "song_name" => data['name'],
        "artist" => data['artists'][0]['name'],
        "album_name" => 'DJ节目',
        "mp3_url" => data['mp3Url']
      }
      tmp.push channel_info
    end

    tmp
  end

  private

  def http_request(method, action, query = nil)
    connection =
      if method == 'GET'
        Unirest.get(action, headers: @header)
      elsif method == 'POST'
        Unirest.post(action, headers: @header, parameters: query)
      end

    connection.body
  rescue => e
    []
  end
end
