require 'open4'

class Player
  attr_accessor :ui

  def initialize
    self.ui = Ui.new
    @datatype = 'songs'
    @mpg123_thread = nil
    @mpg123_pid = nil
    @playing_flag = false
    @pause_flag = false
    @songs = []
    @idx = 0
    @wait = 0.5
    @carousel = ->(left, right, x){x < left ? right : (x > right ? left : x)}
  end

  def recall
    @playing_flag = true
    @pause_flag = false

    item = @songs[@idx]
    ui.build_playinfo(item['song_name'], item['artist'])

    @thread = Thread.new do
      @mp3id, stdin, stdout, stderr = Open4::popen4('mpg123', item['mp3_url'])
      Process::waitpid2 @mp3id

      if @playing_flag
        @idx = @carousel[0, @songs.size - 1, @idx + 1]
        recall
      end
    end
  end

  def play(datatype, songs, idx, switch_flag = false)
    @datatype = datatype

    if !switch_flag
      @pause_flag ? resume : pause if @playing_flag
    elsif switch_flag
      @songs = songs
      @idx = idx
      @playing_flag ? switch : recall
    end
  end

  def switch
    stop
    sleep @wait
    recall
  end

  def stop
    return unless @playing_flag
    return unless @thread
    return unless @mp3id

    @playing_flag = false
    # kill this process and thread
    Process.kill(:SIGKILL, @mp3id)
    Thread.kill @thread
  end

  def pause
    @pause_flag = true
    # send SIGSTOP to pipe
    Process.kill(:SIGSTOP, @mp3id)

    item = @songs[@idx]
    ui.build_playinfo(item['song_name'], item['artist'], true)
  end

  def resume
    @pause_flag = false
    # send SIGCONT to pipe
    Process.kill(:SIGCONT, @mp3id)

    item = @songs[@idx]
    ui.build_playinfo(item['song_name'], item['artist'])
  end

  def next
    stop
    sleep @wait

    @idx = @carousel[0, @songs.size - 1, @idx + 1]
    recall
  end

  def prev
    stop
    sleep @wait

    @idx = @carousel[0, @songs.size - 1, @idx - 1]
    recall
  end
end
