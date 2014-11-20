# Mdisc

![Mdisc](http://cl.ly/Y6Qz)

Mdisc, built with Ruby 2.1, is a command line music player that wirelessly plugs in Netease music(http://music.163.com).

## Installation

My MacBook Pro is running Yosemite(OS X 10.10), Mdisc runs smoothly with Ruby 2.1.

You're lucky if you use Mac OS X. Just follow:

```
$ brew install mpg123
$ gem install mdisc
```

After finishing the installation, open your terminal and input `mdisc`. Music's coming!

Sorry, I do not test Mdisc in Linux. If you try it in Linux and catch some problem, please issue me. Thanks!

## Shortcut

| Key | Explanation          | 中文释义              |
| :---|:---------------------|:---------------------|
| j   | Down                 | 向下                  |
| k   | Up                   | 向上                  |
| h   | Back                 | 后退                  |
| l   | Forward              | 前进或播放高亮选中歌曲   |
| [   | Prev Song            | 上一首歌曲             |
| ]   | Next Song            | 下一首歌曲             |
| ' ' | Play / Pause         | 播放 / 暂停当前进行的歌曲|
| u   | Prev Page            | 上一页列表             |
| d   | Next Page            | 下一页列表             |
| f   | Search               | 搜索                  |
| m   | Main Menu            | 主菜单                |
| p   | Present Playlist     | 当前播放列表           |
| s   | Star                 | 收藏歌曲、精选歌单、专辑 |
| t   | Playlist             | 收藏精选歌单           |
| c   | Collection           | 收藏歌曲列表           |
| a   | Album                | 收藏专辑              |
| z   | DJ Channels          | 收藏 DJ 节目          |
| r   | Remove Present Entry | 删除当前曲目           |
| q   | Quit                 | 退出                  |

## Attention

Mdisc will make a new directory `~/.mdisc` and touch a file to store user's data for the first time.

## Thanks

[NetEase-MusicBox](https://github.com/bluetomlee/NetEase-MusicBox)

[网易云音乐API分析](https://github.com/yanunon/NeteaseCloudMusic/wiki/网易云音乐API分析)

Their great projects inspired me. Thanks!

## License

MIT License.
