MPDRemote
==============

[![Twitter: @Nyx0uf](https://img.shields.io/badge/contact-@Nyx0uf-blue.svg?style=flat)](https://twitter.com/Nyx0uf) [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/Nyx0uf/MPDRemote/blob/master/LICENSE.md) [![Swift Version](https://img.shields.io/badge/Swift-3.0-orange.svg)]()

![screenshot1](https://mpdremote.whine.fr/img/demo-screen-2.gif)

**MPDRemote** is an iOS application to control a [mpd](http://www.musicpd.org/) server. It is written in Swift 3 and requires at least iOS 10.


         | FEATURES
---------|---------------
🗄 | Browse by albums, artists, genres, playlists
🔎 | Fuzzy search for albums, artists, genres
⏪ ⏯ ⏩ | Play, pause, next, previous
🔀 🔁 | Shuffle & repeat
🔈 🔊 | Volume control
📍 | Track position control
➕ | Add album, artist, genre, playlist to current play queue
💬 | VoiceOver compliant
🌐 | Automatically find mpd server with Bonjour/Zeroconf
🇬🇧 🇫🇷 | English and French localized

There is no persistence layer apart from cover caching.

         | TODO
---------|---------------
⚡️ | Optimize things? not slow anyway, works well with an iPhone 5 and 3000+ albums
📱 | iPad version
⚙ | Better icons for consistency, I took random free icons on the net. Problem is my skills in design are (void*)0.
🏁 | Put it on the AppStore ? But I have no money.

LICENSES
-----------------

The mpd static library included is built from [libmpdclient](https://github.com/cmende/libmpdclient) and is released under the revised BSD License.

**MPDRemote** itself is released under the MIT License, see LICENSE.md file.
