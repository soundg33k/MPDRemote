**MPDRemote** is an iOS application to control a [mpd](http://www.musicpd.org/) server. It is written in Swift.

![screenshot1](https://mpdremote.whine.io/images/sc.jpg)

There's no persistence layer apart from cover caching.

### FEATURES

- Browse by albums / genres / artists
- Search
- Play / pause, shuffle, repeat
- Shake to play a random album
- Add album to play queue
- VoiceOver compliant
- English and French localized

### TODO

- [X] Full player view
- [X] Possibility to browse by Artists, Genre, etc… **[WIP]**
- [ ] Optimize things
- [ ] Add some settings
- [ ] iPad version
- [ ] Persistence layer? probably not since it's quite fast on a local network and my 40K musical library evolve quite often
- [ ] An app icon, that won't be me since my design skills are (void*)0
- [ ] Better buttons icons, I took random free icons on the net, but same problem as above

### LICENSE

The mpd static library included is built from [libmpdclient](https://github.com/cmende/libmpdclient) and is released under the revised BSD License.

**MPDRemote** is released under the MIT License, see LICENSE file.
