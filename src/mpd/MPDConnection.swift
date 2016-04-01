// MPDConnection.swift
// Copyright (c) 2016 Nyx0uf ( https://mpdremote.whine.io )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import MPDCLIENT
import UIKit


@objc protocol MPDConnectionDelegate : class
{
	optional func albumMatchingName(name: String) -> Album?
}


public let kPlayerTrackKey = "track"
public let kPlayerAlbumKey = "album"
public let kPlayerElapsedKey = "elapsed"
public let kPlayerStatusKey = "status"


final class MPDConnection
{
	// MARK: - Public properties
	// mpd server
	let server: MPDServer
	// Delegate
	weak var delegate: MPDConnectionDelegate?
	// Connected flag
	private(set) var connected = false

	// MARK: - Private properties
	// mpd_connection object
	private var _connection: COpaquePointer = nil
	// Timeout in seconds
	private let _timeout = UInt32(30)

	// MARK: - Initializers
	init(server: MPDServer)
	{
		self.server = server
	}

	deinit
	{
		self.disconnect()
	}

	// MARK: - Public
	func connect() -> Bool
	{
		// Open connection
		self._connection = mpd_connection_new(self.server.hostname, UInt32(self.server.port), self._timeout * 1000)
		if mpd_connection_get_error(self._connection) != MPD_ERROR_SUCCESS
		{
			Logger.dlog("[!] connect(): \(self._getErrorMessageForConnection(self._connection))")
			self._connection = nil
			return false
		}
		// Keep alive
		//mpd_connection_set_keepalive(self._connection, true)

		// Set password if needed
		if self.server.password.length > 0
		{
			if !mpd_run_password(self._connection, self.server.password)
			{
				Logger.dlog("[!] mpd_run_password(): \(self._getErrorMessageForConnection(self._connection))")
				mpd_connection_free(self._connection)
				self._connection = nil
				return false
			}
		}

		self.connected = true
		return true
	}
	
	func disconnect()
	{
		if self._connection != nil
		{
			mpd_connection_free(self._connection)
			self._connection = nil
		}
		self.connected = false
	}

	// MARK: - Public
	func getAlbumsList() -> [Album]
	{
		var list = [Album]()
		if (!mpd_search_db_tags(self._connection, MPD_TAG_ALBUM) || !mpd_search_commit(self._connection))
		{
			Logger.dlog("getAlbumsList: mpd_search_db_tags")
			return list
		}
		
		var p = mpd_recv_pair_tag(self._connection, MPD_TAG_ALBUM)
		if p == nil
		{
			Logger.dlog("no albums?")
			return list
		}

		repeat
		{
			let m = p.memory
			let albumName = NSString(bytes:m.value, length:Int(strlen(m.value)), encoding:NSUTF8StringEncoding) as! String
			
			list.append(Album(name:albumName))
			
			mpd_return_pair(self._connection, p)
			p = mpd_recv_pair_tag(self._connection, MPD_TAG_ALBUM)
		} while p != nil

		if (mpd_connection_get_error(self._connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(self._connection))
		{
			Logger.dlog("getAlbumsList: mpd_connection_get_error")
			return list
		}

		return list
	}

	func findCoverForAlbum(album: Album)
	{
		if (!mpd_search_db_songs(self._connection, true))
		{
			Logger.dlog("findCoverForAlbum: \(self._getErrorMessageForConnection(self._connection))")
			return
		}
		if (!mpd_search_add_tag_constraint(self._connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name))
		{
			Logger.dlog("findCoverForAlbum: \(self._getErrorMessageForConnection(self._connection))")
			return
		}
		if (!mpd_search_commit(self._connection))
		{
			Logger.dlog("findCoverForAlbum: \(self._getErrorMessageForConnection(self._connection))")
			return
		}
		
		let song = mpd_recv_song(self._connection)
		if song != nil
		{
			let r = mpd_song_get_uri(song)
			let trackName = NSString(bytes:r, length:Int(strlen(r)), encoding:NSUTF8StringEncoding) as! String
			album.path = NSURL(fileURLWithPath:trackName).URLByDeletingLastPathComponent!.path
		}
		if (mpd_connection_get_error(self._connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(self._connection))
		{
			Logger.dlog("findCoverForAlbum: \(self._getErrorMessageForConnection(self._connection))")
			return
		}
	}

	func getSongsForAlbum(album: Album) -> [Track]?
	{
		if (!mpd_search_db_songs(self._connection, true))
		{
			Logger.dlog("getSongsForAlbum: mpd_search_db_songs")
			return nil
		}
		if (!mpd_search_add_tag_constraint(self._connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name))
		{
			Logger.dlog("getSongsForAlbum: mpd_search_add_tag_constraint")
			return nil
		}
		if album.artist.length > 0
		{
			if (!mpd_search_add_tag_constraint(self._connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM_ARTIST, album.artist))
			{
				Logger.dlog("getSongsForAlbum: mpd_search_add_tag_constraint")
				return nil
			}
		}
		if (!mpd_search_commit(self._connection))
		{
			Logger.dlog("getSongsForAlbum: mpd_search_commit")
			return nil
		}
		
		var song = mpd_recv_song(self._connection)
		if song == nil
		{
			Logger.dlog("no songs?")
			return nil
		}
		
		var list = [Track]()
		repeat
		{
			list.append(self._trackFromSongObject(song))
			song = mpd_recv_song(self._connection)
		} while song != nil
		
		if (mpd_connection_get_error(self._connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(self._connection))
		{
			Logger.dlog("getSongsForAlbum: mpd_response_finish")
			return nil
		}
		
		return list
	}

	func getMetadatasForAlbum(album: Album)
	{
		// Find album artist
		if !mpd_search_db_tags(self._connection, MPD_TAG_ALBUM_ARTIST)
		{
			Logger.dlog("getMetadatasForAlbum: mpd_search_db_tags")
			return
		}
		if !mpd_search_add_tag_constraint(self._connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name)
		{
			Logger.dlog("getMetadatasForAlbum: mpd_search_add_tag_constraint")
			return
		}
		if !mpd_search_commit(self._connection)
		{
			Logger.dlog("getMetadatasForAlbum: mpd_search_commit")
			return
		}
		let tmpArtist = mpd_recv_pair_tag(self._connection, MPD_TAG_ALBUM_ARTIST)
		if tmpArtist != nil
		{
			let m = tmpArtist.memory
			let artist = NSString(bytes:m.value, length:Int(strlen(m.value)), encoding:NSUTF8StringEncoding) as! String
			album.artist = artist
		}
		mpd_return_pair(self._connection, tmpArtist)
		if (mpd_connection_get_error(self._connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(self._connection))
		{
			Logger.dlog("getMetadatasForAlbum: mpd_connection_get_error")
			return
		}
		
		// Find album year
		if !mpd_search_db_tags(self._connection, MPD_TAG_DATE)
		{
			Logger.dlog("getMetadatasForAlbum: mpd_search_db_tags")
			return
		}
		if !mpd_search_add_tag_constraint(self._connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name)
		{
			Logger.dlog("getMetadatasForAlbum: mpd_search_add_tag_constraint")
			return
		}
		if !mpd_search_commit(self._connection)
		{
			Logger.dlog("getMetadatasForAlbum: mpd_search_commit")
			return
		}
		let tmpDate = mpd_recv_pair_tag(self._connection, MPD_TAG_DATE)
		if tmpDate != nil
		{
			let m = tmpDate.memory
			var l = Int(strlen(m.value))
			if l > 4
			{
				l = 4
			}
			let artist = NSString(bytes:m.value, length:l, encoding:NSUTF8StringEncoding) as! String
			album.year = artist
		}
		mpd_return_pair(self._connection, tmpDate)
		if (mpd_connection_get_error(self._connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(self._connection))
		{
			Logger.dlog("getMetadatasForAlbum: mpd_connection_get_error")
			return
		}
		
		// Find album genre
		if !mpd_search_db_tags(self._connection, MPD_TAG_GENRE)
		{
			Logger.dlog("getMetadatasForAlbum: mpd_search_db_tags")
			return
		}
		if !mpd_search_add_tag_constraint(self._connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name)
		{
			Logger.dlog("getMetadatasForAlbum: mpd_search_add_tag_constraint")
			return
		}
		if !mpd_search_commit(self._connection)
		{
			Logger.dlog("getMetadatasForAlbum: mpd_search_commit")
			return
		}
		let tmpGenre = mpd_recv_pair_tag(self._connection, MPD_TAG_GENRE)
		if tmpGenre != nil
		{
			let m = tmpGenre.memory
			let artist = NSString(bytes:m.value, length:Int(strlen(m.value)), encoding:NSUTF8StringEncoding) as! String
			album.genre = artist
		}
		mpd_return_pair(self._connection, tmpGenre)
		if (mpd_connection_get_error(self._connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(self._connection))
		{
			Logger.dlog("getMetadatasForAlbum: mpd_connection_get_error")
			return
		}
	}

	func playAlbum(album: Album, random: Bool, loop: Bool)
	{
		if let songs = album.songs
		{
			self.playTracks(songs, random:random, loop:loop)
		}
		else
		{
			if let songs = self.getSongsForAlbum(album)
			{
				album.songs = songs
				self.playTracks(songs, random:random, loop:loop)
			}
		}
	}

	func playTracks(tracks: [Track], random: Bool, loop: Bool)
	{
		if !mpd_run_clear(self._connection)
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return
		}

		self.setRandom(random)

		for track in tracks
		{
			if !mpd_run_add(self._connection, track.uri)
			{
				Logger.dlog(self._getErrorMessageForConnection(self._connection))
				return
			}
		}

		/*if random
		{
			if !mpd_run_shuffle(self._connection)
			{
				Logger.dlog(self._getErrorMessageForConnection(self._connection))
			}
		}*/

		if !mpd_run_play_pos(self._connection, 0)
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
		}

		//self.setRandom(random)
	}
	
	func addAlbumToQueue(album: Album)
	{
		if let tracks = album.songs
		{
			for track in tracks
			{
				if !mpd_run_add(self._connection, track.uri)
				{
					Logger.dlog(self._getErrorMessageForConnection(self._connection))
					return
				}
			}
		}
		else
		{
			if let tracks = self.getSongsForAlbum(album)
			{
				album.songs = tracks
				for track in tracks
				{
					if !mpd_run_add(self._connection, track.uri)
					{
						Logger.dlog(self._getErrorMessageForConnection(self._connection))
						return
					}
				}
			}
		}
	}

	func getPlayerStatus() -> [String: AnyObject]?
	{
		let song = mpd_run_current_song(self._connection)
		if song == nil
		{
			Logger.dlog("[!] No current song.")
			return nil
		}

		let status = mpd_run_status(self._connection)
		if status == nil
		{
			Logger.dlog("[!] No status.")
			return nil
		}

		let elapsed = mpd_status_get_elapsed_time(status)
		let track = self._trackFromSongObject(song)
		let state = self._stateFromStateObject(mpd_status_get_state(status))
		let tmp = mpd_song_get_tag(song, MPD_TAG_ALBUM, 0)
		let albumName = NSString(bytes:tmp, length:Int(strlen(tmp)), encoding:NSUTF8StringEncoding) as! String
		if let album = self.delegate?.albumMatchingName!(albumName)
		{
			return [kPlayerTrackKey : track, kPlayerAlbumKey : album, kPlayerElapsedKey : Int(elapsed), kPlayerStatusKey : state.rawValue]
		}
		Logger.dlog("[!] No matching album found.")
		return nil
	}

	func pausePlayback() -> Bool
	{
		return mpd_run_pause(self._connection, true)
	}

	func runPlayback() -> Bool
	{
		return mpd_run_play(self._connection)
	}

	func togglePause() -> Bool
	{
		return mpd_run_toggle_pause(self._connection)
	}

	func setRandom(random: Bool)
	{
		if !mpd_run_random(self._connection, random)
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
		}
	}

	func setRepeat(loop: Bool)
	{
		if !mpd_run_repeat(self._connection, loop)
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
		}
	}

	func nextTrack()
	{
		if !mpd_run_next(self._connection)
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
		}
	}

	func previousTrack()
	{
		if !mpd_run_previous(self._connection)
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
		}
	}

	func setTrackPosition(position: Int, trackPosition: UInt32)
	{
		if !mpd_run_seek_pos(self._connection, trackPosition, UInt32(position))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
		}
	}

	// MARK: - Private
	private func _getErrorMessageForConnection(connection: COpaquePointer) -> String
	{
		let err = mpd_connection_get_error_message(self._connection)
		let msg = NSString(bytes:err, length:Int(strlen(err)), encoding:NSUTF8StringEncoding) as! String
		return msg
	}

	private func _trackFromSongObject(song: COpaquePointer) -> Track
	{
		// title
		var tmp = mpd_song_get_tag(song, MPD_TAG_TITLE, 0)
		let title = NSString(bytes:tmp, length:Int(strlen(tmp)), encoding:NSUTF8StringEncoding) as! String
		// artist
		tmp = mpd_song_get_tag(song, MPD_TAG_ARTIST, 0)
		let artist = NSString(bytes:tmp, length:Int(strlen(tmp)), encoding:NSUTF8StringEncoding) as! String
		// track number
		tmp = mpd_song_get_tag(song, MPD_TAG_TRACK, 0)
		var trackNumber = NSString(bytes:tmp, length:Int(strlen(tmp)), encoding:NSUTF8StringEncoding) as! String
		trackNumber = trackNumber.componentsSeparatedByString("/").first!
		// duration
		let duration = mpd_song_get_duration(song)
		// uri
		tmp = mpd_song_get_uri(song)
		let uri = NSString(bytes:tmp, length:Int(strlen(tmp)), encoding:NSUTF8StringEncoding) as! String
		// Position in the queue
		let pos = mpd_song_get_pos(song)
		
		// create track
		let track = Track(title:title, artist:artist, duration:Duration(seconds:UInt(duration)), trackNumber:Int(trackNumber)!, uri:uri)
		track.position = pos
		return track
	}

	private func _stateFromStateObject(state: mpd_state) -> PlayerStatus
	{
		switch state
		{
		case MPD_STATE_PLAY:
			return .Playing
		case MPD_STATE_PAUSE:
			return .Paused
		case MPD_STATE_STOP:
			return .Stopped
		default:
			return .Unknown
		}
	}
}
