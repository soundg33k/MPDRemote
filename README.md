**MPDRemote** is an iOS application to control a [mpd](http://www.musicpd.org/) server. It is written in Swift 3.

![screenshot1](https://static.whine.fr/images/2016/mpdremote1.jpg)

There's no persistence layer apart from cover caching.

### FEATURES

- Browse by Albums / Artists / Genres
- Search
- Play / pause, shuffle, repeat
- Shake to play a random album
- Add album / artist / genre to play queue
- VoiceOver compliant
- Automatically find mpd server with Zeroconf
- English and French localized

### TODO

- [X] Full player view
- [X] Possibility to browse by Artists, Genre…
- [ ] Optimize things
- [ ] Add some settings
- [ ] iPad version
- [ ] Persistence layer? probably not since it's quite fast on a local network and my 40K musical library evolve quite often
- [X] An app icon
- [ ] Better icons for consistency, I took random free icons on the net. Problem is my skills in design are (void*)0.

### LICENSE

The mpd static library included is built from [libmpdclient](https://github.com/cmende/libmpdclient) and is released under the revised BSD License.

**MPDRemote** is released under the MIT License, see LICENSE file.
