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

	// MARK: - Connection
	func connect() -> Bool
	{
		// Open connection
		self._connection = mpd_connection_new(self.server.hostname, UInt32(self.server.port), self._timeout * 1000)
		if mpd_connection_get_error(self._connection) != MPD_ERROR_SUCCESS
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
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
				Logger.dlog(self._getErrorMessageForConnection(self._connection))
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

	// MARK: - Get infos about tracks / albums / etc…
	func getListForDisplayType(displayType: DisplayType) -> [AnyObject]
	{
		let tagType = self._mpdTagTypeFromDisplayType(displayType)

		var list = [AnyObject]()
		if (!mpd_search_db_tags(self._connection, tagType) || !mpd_search_commit(self._connection))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return list
		}

		var pair = mpd_recv_pair_tag(self._connection, tagType)
		while pair != nil
		{
			if let name = String(data:NSData(bytesNoCopy:UnsafeMutablePointer<Void>(pair.memory.value), length:Int(strlen(pair.memory.value)), freeWhenDone:false), encoding:NSUTF8StringEncoding)
			{
				switch displayType
				{
					case .Albums:
						list.append(Album(name:name))
					case .Genres:
						list.append(Genre(name:name))
					case .Artists:
						list.append(Artist(name:name))
				}
			}

			mpd_return_pair(self._connection, pair)
			pair = mpd_recv_pair_tag(self._connection, tagType)
		}

		if (mpd_connection_get_error(self._connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(self._connection))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
		}

		return list
	}

	func getAlbumForGenre(genre: Genre) -> Album?
	{
		if (!mpd_search_db_tags(self._connection, MPD_TAG_ALBUM))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return nil
		}
		if (!mpd_search_add_tag_constraint(self._connection, MPD_OPERATOR_DEFAULT, MPD_TAG_GENRE, genre.name))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return nil
		}
		if (!mpd_search_commit(self._connection))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return nil
		}

		let pair = mpd_recv_pair_tag(self._connection, MPD_TAG_ALBUM)
		if pair == nil
		{
			Logger.dlog("[!] No pair.")
			return nil
		}

		guard let name = String(data:NSData(bytesNoCopy:UnsafeMutablePointer<Void>(pair.memory.value), length:Int(strlen(pair.memory.value)), freeWhenDone:false), encoding:NSUTF8StringEncoding) else
		{
			Logger.dlog("[!] Invalid name.")
			mpd_return_pair(self._connection, pair)
			return nil
		}
		mpd_return_pair(self._connection, pair)

		if (mpd_connection_get_error(self._connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(self._connection))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
		}

		return Album(name:name)
	}

	func getAlbumsForGenre(genre: Genre) -> [Album]
	{
		var list = [Album]()

		if (!mpd_search_db_tags(self._connection, MPD_TAG_ALBUM))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return list
		}
		if (!mpd_search_add_tag_constraint(self._connection, MPD_OPERATOR_DEFAULT, MPD_TAG_GENRE, genre.name))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return list
		}
		if (!mpd_search_commit(self._connection))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return list
		}

		var pair = mpd_recv_pair_tag(self._connection, MPD_TAG_ALBUM)
		while pair != nil
		{
			if let name = String(data:NSData(bytesNoCopy:UnsafeMutablePointer<Void>(pair.memory.value), length:Int(strlen(pair.memory.value)), freeWhenDone:false), encoding:NSUTF8StringEncoding)
			{
				if let album = self.delegate?.albumMatchingName!(name)
				{
					list.append(album)
				}
			}

			mpd_return_pair(self._connection, pair)
			pair = mpd_recv_pair_tag(self._connection, MPD_TAG_ALBUM)
		}

		if (mpd_connection_get_error(self._connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(self._connection))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
		}

		return list
	}

	func getAlbumsForArtist(artist: Artist) -> [Album]
	{
		var list = [Album]()

		if (!mpd_search_db_tags(self._connection, MPD_TAG_ALBUM))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return list
		}
		if (!mpd_search_add_tag_constraint(self._connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ARTIST, artist.name))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return list
		}
		if (!mpd_search_commit(self._connection))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return list
		}

		var pair = mpd_recv_pair_tag(self._connection, MPD_TAG_ALBUM)
		while pair != nil
		{
			if let name = String(data:NSData(bytesNoCopy:UnsafeMutablePointer<Void>(pair.memory.value), length:Int(strlen(pair.memory.value)), freeWhenDone:false), encoding:NSUTF8StringEncoding)
			{
				if let album = self.delegate?.albumMatchingName!(name)
				{
					list.append(album)
				}
			}

			mpd_return_pair(self._connection, pair)
			pair = mpd_recv_pair_tag(self._connection, MPD_TAG_ALBUM)
		}

		if (mpd_connection_get_error(self._connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(self._connection))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
		}

		return list
	}

	func getArtistsForGenre(genre: Genre) -> [Artist]
	{
		var list = [Artist]()

		if (!mpd_search_db_tags(self._connection, MPD_TAG_ARTIST))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return list
		}
		if (!mpd_search_add_tag_constraint(self._connection, MPD_OPERATOR_DEFAULT, MPD_TAG_GENRE, genre.name))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return list
		}
		if (!mpd_search_commit(self._connection))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return list
		}

		var pair = mpd_recv_pair_tag(self._connection, MPD_TAG_ARTIST)
		while pair != nil
		{
			if let name = String(data:NSData(bytesNoCopy:UnsafeMutablePointer<Void>(pair.memory.value), length:Int(strlen(pair.memory.value)), freeWhenDone:false), encoding:NSUTF8StringEncoding)
			{
				list.append(Artist(name:name))
			}
			
			mpd_return_pair(self._connection, pair)
			pair = mpd_recv_pair_tag(self._connection, MPD_TAG_ARTIST)
		}

		if (mpd_connection_get_error(self._connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(self._connection))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
		}

		return list
	}

	func getPathForAlbum(album: Album) -> String?
	{
		var path: String? = nil
		if (!mpd_search_db_songs(self._connection, true))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return path
		}
		if (!mpd_search_add_tag_constraint(self._connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return path
		}
		if (!mpd_search_commit(self._connection))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return path
		}

		let song = mpd_recv_song(self._connection)
		if song != nil
		{
			let uri = mpd_song_get_uri(song)
			if uri != nil
			{
				if let name = String(data:NSData(bytesNoCopy:UnsafeMutablePointer<Void>(uri), length:Int(strlen(uri)), freeWhenDone:false), encoding:NSUTF8StringEncoding)
				{
					path = NSURL(fileURLWithPath:name).URLByDeletingLastPathComponent!.path
				}
			}
		}

		if (mpd_connection_get_error(self._connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(self._connection))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
		}

		return path
	}

	func getSongsForAlbum(album: Album) -> [Track]?
	{
		if (!mpd_search_db_songs(self._connection, true))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return nil
		}
		if (!mpd_search_add_tag_constraint(self._connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return nil
		}
		if album.artist.length > 0
		{
			if (!mpd_search_add_tag_constraint(self._connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM_ARTIST, album.artist))
			{
				Logger.dlog(self._getErrorMessageForConnection(self._connection))
				return nil
			}
		}
		if (!mpd_search_commit(self._connection))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return nil
		}

		var list = [Track]()
		var song = mpd_recv_song(self._connection)
		while song != nil
		{
			if let track = self._trackFromMPDSongObject(song)
			{
				list.append(track)
			}
			song = mpd_recv_song(self._connection)
		}

		if (mpd_connection_get_error(self._connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(self._connection))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
		}

		return list
	}

	func getMetadatasForAlbum(album: Album) -> [String : AnyObject]
	{
		var metadatas = [String : AnyObject]()
		// Find album artist
		if !mpd_search_db_tags(self._connection, MPD_TAG_ALBUM_ARTIST)
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return metadatas
		}
		if !mpd_search_add_tag_constraint(self._connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name)
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return metadatas
		}
		if !mpd_search_commit(self._connection)
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return metadatas
		}
		let tmpArtist = mpd_recv_pair_tag(self._connection, MPD_TAG_ALBUM_ARTIST)
		if tmpArtist != nil
		{
			if let name = String(data:NSData(bytesNoCopy:UnsafeMutablePointer<Void>(tmpArtist.memory.value), length:Int(strlen(tmpArtist.memory.value)), freeWhenDone:false), encoding:NSUTF8StringEncoding)
			{
				metadatas["artist"] = name
			}
		}
		mpd_return_pair(self._connection, tmpArtist)
		if (mpd_connection_get_error(self._connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(self._connection))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return metadatas
		}

		// Find album year
		if !mpd_search_db_tags(self._connection, MPD_TAG_DATE)
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return metadatas
		}
		if !mpd_search_add_tag_constraint(self._connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name)
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return metadatas
		}
		if !mpd_search_commit(self._connection)
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return metadatas
		}
		let tmpDate = mpd_recv_pair_tag(self._connection, MPD_TAG_DATE)
		if tmpDate != nil
		{
			var l = Int(strlen(tmpDate.memory.value))
			if l > 4
			{
				l = 4
			}
			if let year = String(data:NSData(bytesNoCopy:UnsafeMutablePointer<Void>(tmpDate.memory.value), length:Int(strlen(tmpDate.memory.value)), freeWhenDone:false), encoding:NSUTF8StringEncoding)
			{
				metadatas["year"] = year
			}
		}
		mpd_return_pair(self._connection, tmpDate)
		if (mpd_connection_get_error(self._connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(self._connection))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return metadatas
		}

		// Find album genre
		if !mpd_search_db_tags(self._connection, MPD_TAG_GENRE)
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return metadatas
		}
		if !mpd_search_add_tag_constraint(self._connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name)
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return metadatas
		}
		if !mpd_search_commit(self._connection)
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
			return metadatas
		}
		let tmpGenre = mpd_recv_pair_tag(self._connection, MPD_TAG_GENRE)
		if tmpGenre != nil
		{
			if let genre = String(data:NSData(bytesNoCopy:UnsafeMutablePointer<Void>(tmpGenre.memory.value), length:Int(strlen(tmpGenre.memory.value)), freeWhenDone:false), encoding:NSUTF8StringEncoding)
			{
				metadatas["genre"] = genre
			}
		}
		mpd_return_pair(self._connection, tmpGenre)
		if (mpd_connection_get_error(self._connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(self._connection))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
		}

		return metadatas
	}

	// MARK: - Play / Queue
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
		self.setRepeat(loop)

		for track in tracks
		{
			if !mpd_run_add(self._connection, track.uri)
			{
				Logger.dlog(self._getErrorMessageForConnection(self._connection))
				return
			}
		}

		if !mpd_run_play_pos(self._connection, random ? arc4random_uniform(UInt32(tracks.count)) : 0)
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
		}
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

	func togglePause() -> Bool
	{
		return mpd_run_toggle_pause(self._connection)
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

	func setTrackPosition(position: Int, trackPosition: UInt32)
	{
		if !mpd_run_seek_pos(self._connection, trackPosition, UInt32(position))
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
		}
	}

	// MARK: - Player status
	func getStatus()
	{
		let ret = mpd_run_status(self._connection)
		if ret == nil
		{
			Logger.dlog(self._getErrorMessageForConnection(self._connection))
		}
	}

	func getPlayerInfos() -> [String: AnyObject]?
	{
		let song = mpd_run_current_song(self._connection)
		if song == nil
		{
			return nil
		}

		let status = mpd_run_status(self._connection)
		if status == nil
		{
			Logger.dlog("[!] No status.")
			return nil
		}

		let elapsed = mpd_status_get_elapsed_time(status)
		guard let track = self._trackFromMPDSongObject(song) else
		{
			return nil
		}
		let state = self._statusFromMPDStateObject(mpd_status_get_state(status))
		let tmp = mpd_song_get_tag(song, MPD_TAG_ALBUM, 0)
		if let name = String(data:NSData(bytesNoCopy:UnsafeMutablePointer<Void>(tmp), length:Int(strlen(tmp)), freeWhenDone:false), encoding:NSUTF8StringEncoding)
		{
			if let album = self.delegate?.albumMatchingName!(name)
			{
				return [kPlayerTrackKey : track, kPlayerAlbumKey : album, kPlayerElapsedKey : Int(elapsed), kPlayerStatusKey : state.rawValue]
			}
		}

		Logger.dlog("[!] No matching album found.")
		return nil
	}

	// MARK: - Private
	private func _getErrorMessageForConnection(connection: COpaquePointer) -> String
	{
		let err = mpd_connection_get_error_message(self._connection)
		if let msg = String(data:NSData(bytesNoCopy:UnsafeMutablePointer<Void>(err), length:Int(strlen(err)), freeWhenDone:false), encoding:NSUTF8StringEncoding)
		{
			return msg
		}
		return "NO ERROR MESSAGE"
	}

	private func _trackFromMPDSongObject(song: COpaquePointer) -> Track?
	{
		// title
		var tmp = mpd_song_get_tag(song, MPD_TAG_TITLE, 0)
		guard let title = String(data:NSData(bytesNoCopy:UnsafeMutablePointer<Void>(tmp), length:Int(strlen(tmp)), freeWhenDone:false), encoding:NSUTF8StringEncoding) else
		{
			return nil
		}
		// artist
		tmp = mpd_song_get_tag(song, MPD_TAG_ARTIST, 0)
		guard let artist = String(data:NSData(bytesNoCopy:UnsafeMutablePointer<Void>(tmp), length:Int(strlen(tmp)), freeWhenDone:false), encoding:NSUTF8StringEncoding) else
		{
			return nil
		}
		// track number
		tmp = mpd_song_get_tag(song, MPD_TAG_TRACK, 0)
		guard var trackNumber = String(data:NSData(bytesNoCopy:UnsafeMutablePointer<Void>(tmp), length:Int(strlen(tmp)), freeWhenDone:false), encoding:NSUTF8StringEncoding) else
		{
			return nil
		}
		trackNumber = trackNumber.componentsSeparatedByString("/").first!
		// duration
		let duration = mpd_song_get_duration(song)
		// uri
		tmp = mpd_song_get_uri(song)
		guard let uri = String(data:NSData(bytesNoCopy:UnsafeMutablePointer<Void>(tmp), length:Int(strlen(tmp)), freeWhenDone:false), encoding:NSUTF8StringEncoding) else
		{
			return nil
		}
		// Position in the queue
		let pos = mpd_song_get_pos(song)

		// create track
		let trackNumInt = Int(trackNumber) ?? 1
		let track = Track(title:title, artist:artist, duration:Duration(seconds:UInt(duration)), trackNumber:trackNumInt, uri:uri)
		track.position = pos
		return track
	}

	private func _statusFromMPDStateObject(state: mpd_state) -> PlayerStatus
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

	private func _mpdTagTypeFromDisplayType(displayType: DisplayType) -> mpd_tag_type
	{
		switch displayType
		{
			case .Albums:
				return MPD_TAG_ALBUM
			case .Genres:
				return MPD_TAG_GENRE
			case .Artists:
				return MPD_TAG_ARTIST
		}
	}
}
