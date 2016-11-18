// MPDConnection.swift
// Copyright (c) 2016 Nyx0uf
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


final class MPDConnection : AudioServerConnection
{
	// MARK: - Public properties
	// mpd server
	let server: AudioServer
	// Delegate
	weak var delegate: AudioServerConnectionDelegate?
	// Connected flag
	private(set) var connected = false

	// MARK: - Private properties
	// mpd_connection object
	private var _connection: OpaquePointer? = nil
	// Timeout in seconds
	private let _timeout = UInt32(10)

	// MARK: - Initializers
	init(server: AudioServer)
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
		_connection = mpd_connection_new(server.hostname, UInt32(server.port), _timeout * 1000)
		if mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			_connection = nil
			return false
		}
		// Keep alive
		//mpd_connection_set_keepalive(_connection, true)

		// Set password if needed
		if server.password.length > 0
		{
			if !mpd_run_password(_connection, server.password)
			{
				Logger.dlog(getErrorMessageForConnection(_connection!))
				mpd_connection_free(_connection)
				_connection = nil
				return false
			}
		}

		connected = true
		return true
	}

	func disconnect()
	{
		if _connection != nil
		{
			mpd_connection_free(_connection)
			_connection = nil
		}
		connected = false
	}

	// MARK: - Get infos about tracks / albums / etc…
	func getListForDisplayType(_ displayType: DisplayType) -> [Any]
	{
		let tagType = mpdTagTypeFromDisplayType(displayType)

		var list = [Any]()
		if (!mpd_search_db_tags(_connection, tagType) || !mpd_search_commit(_connection))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return list
		}

		var pair = mpd_recv_pair_tag(_connection, tagType)
		while pair != nil
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: (pair?.pointee.value)!), count: Int(strlen(pair?.pointee.value)), deallocator: .none)
			if let name = String(data: dataTemp, encoding: .utf8)
			{
				switch displayType
				{
					case .albums:
						list.append(Album(name: name))
					case .genres:
						list.append(Genre(name: name))
					case .artists:
						list.append(Artist(name: name))
				}
			}

			mpd_return_pair(_connection, pair)
			pair = mpd_recv_pair_tag(_connection, tagType)
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(_connection))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
		}

		return list
	}

	func getAlbumForGenre(_ genre: Genre) -> Album?
	{
		if (!mpd_search_db_tags(_connection, MPD_TAG_ALBUM))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return nil
		}
		if (!mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_GENRE, genre.name))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return nil
		}
		if (!mpd_search_commit(_connection))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return nil
		}

		let pair = mpd_recv_pair_tag(_connection, MPD_TAG_ALBUM)
		if pair == nil
		{
			Logger.dlog("[!] No pair.")
			return nil
		}

		let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: (pair?.pointee.value)!), count: Int(strlen(pair?.pointee.value)), deallocator: .none)
		guard let name = String(data: dataTemp, encoding: .utf8) else
		{
			Logger.dlog("[!] Invalid name.")
			mpd_return_pair(_connection, pair)
			return nil
		}
		mpd_return_pair(_connection, pair)

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(_connection))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
		}

		return Album(name: name)
	}

	func getAlbumsForGenre(_ genre: Genre) -> [Album]
	{
		var list = [Album]()

		if (!mpd_search_db_tags(_connection, MPD_TAG_ALBUM))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return list
		}
		if (!mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_GENRE, genre.name))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return list
		}
		if (!mpd_search_commit(_connection))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return list
		}

		var pair = mpd_recv_pair_tag(_connection, MPD_TAG_ALBUM)
		while pair != nil
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: (pair?.pointee.value)!), count: Int(strlen(pair?.pointee.value)), deallocator: .none)
			if let name = String(data: dataTemp, encoding: .utf8)
			{
				if let album = delegate?.albumMatchingName(name)
				{
					list.append(album)
				}
			}

			mpd_return_pair(_connection, pair)
			pair = mpd_recv_pair_tag(_connection, MPD_TAG_ALBUM)
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(_connection))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
		}

		return list
	}

	func getAlbumsForArtist(_ artist: Artist) -> [Album]
	{
		var list = [Album]()

		if (!mpd_search_db_tags(_connection, MPD_TAG_ALBUM))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return list
		}
		if (!mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ARTIST, artist.name))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return list
		}
		if (!mpd_search_commit(_connection))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return list
		}

		var pair = mpd_recv_pair_tag(_connection, MPD_TAG_ALBUM)
		while pair != nil
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: (pair?.pointee.value)!), count: Int(strlen(pair?.pointee.value)), deallocator: .none)
			if let name = String(data: dataTemp, encoding: .utf8)
			{
				if let album = delegate?.albumMatchingName(name)
				{
					list.append(album)
				}
			}

			mpd_return_pair(_connection, pair)
			pair = mpd_recv_pair_tag(_connection, MPD_TAG_ALBUM)
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(_connection))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
		}

		return list
	}

	func getArtistsForGenre(_ genre: Genre) -> [Artist]
	{
		var list = [Artist]()

		if (!mpd_search_db_tags(_connection, MPD_TAG_ARTIST))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return list
		}
		if (!mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_GENRE, genre.name))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return list
		}
		if (!mpd_search_commit(_connection))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return list
		}

		var pair = mpd_recv_pair_tag(_connection, MPD_TAG_ARTIST)
		while pair != nil
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: (pair?.pointee.value)!), count: Int(strlen(pair?.pointee.value)), deallocator: .none)
			if let name = String(data: dataTemp, encoding: .utf8)
			{
				list.append(Artist(name: name))
			}
			
			mpd_return_pair(_connection, pair)
			pair = mpd_recv_pair_tag(_connection, MPD_TAG_ARTIST)
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(_connection))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
		}

		return list
	}

	func getPathForAlbum(_ album: Album) -> String?
	{
		var path: String? = nil
		if (!mpd_search_db_songs(_connection, true))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return path
		}
		if (!mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return path
		}
		if (!mpd_search_commit(_connection))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return path
		}

		let song = mpd_recv_song(_connection)
		if song != nil
		{
			let uri = mpd_song_get_uri(song)
			if uri != nil
			{
				let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: uri!), count: Int(strlen(uri)), deallocator: .none)
				if let name = String(data: dataTemp, encoding: .utf8)
				{
					path = URL(fileURLWithPath: name).deletingLastPathComponent().path
				}
			}
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(_connection))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
		}

		return path
	}

	func getSongsForAlbum(_ album: Album) -> [Track]?
	{
		if (!mpd_search_db_songs(_connection, true))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return nil
		}
		if (!mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return nil
		}
		if album.artist.length > 0
		{
			if (!mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM_ARTIST, album.artist))
			{
				Logger.dlog(getErrorMessageForConnection(_connection!))
				return nil
			}
		}
		if (!mpd_search_commit(_connection))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return nil
		}

		var list = [Track]()
		var song = mpd_recv_song(_connection)
		while song != nil
		{
			if let track = trackFromMPDSongObject(song!)
			{
				list.append(track)
			}
			song = mpd_recv_song(_connection)
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(_connection))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
		}

		return list
	}

	func getMetadatasForAlbum(_ album: Album) -> [String : Any]
	{
		var metadatas = [String : Any]()
		// Find album artist
		if !mpd_search_db_tags(_connection, MPD_TAG_ALBUM_ARTIST)
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return metadatas
		}
		if !mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name)
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return metadatas
		}
		if !mpd_search_commit(_connection)
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return metadatas
		}
		let tmpArtist = mpd_recv_pair_tag(_connection, MPD_TAG_ALBUM_ARTIST)
		if tmpArtist != nil
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: (tmpArtist?.pointee.value)!), count: Int(strlen(tmpArtist?.pointee.value)), deallocator: .none)
			if let name = String(data: dataTemp, encoding: .utf8)
			{
				metadatas["artist"] = name
			}
		}
		mpd_return_pair(_connection, tmpArtist)
		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(_connection))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return metadatas
		}

		// Find album year
		if !mpd_search_db_tags(_connection, MPD_TAG_DATE)
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return metadatas
		}
		if !mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name)
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return metadatas
		}
		if !mpd_search_commit(_connection)
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return metadatas
		}
		let tmpDate = mpd_recv_pair_tag(_connection, MPD_TAG_DATE)
		if tmpDate != nil
		{
			var l = Int(strlen(tmpDate?.pointee.value))
			if l > 4
			{
				l = 4
			}
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: (tmpDate?.pointee.value)!), count: l, deallocator: .none)
			if let year = String(data: dataTemp, encoding: .utf8)
			{
				metadatas["year"] = year
			}
		}
		mpd_return_pair(_connection, tmpDate)
		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(_connection))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return metadatas
		}

		// Find album genre
		if !mpd_search_db_tags(_connection, MPD_TAG_GENRE)
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return metadatas
		}
		if !mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name)
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return metadatas
		}
		if !mpd_search_commit(_connection)
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return metadatas
		}
		let tmpGenre = mpd_recv_pair_tag(_connection, MPD_TAG_GENRE)
		if tmpGenre != nil
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: (tmpGenre?.pointee.value)!), count: Int(strlen(tmpGenre?.pointee.value)), deallocator: .none)
			if let genre = String(data: dataTemp, encoding: .utf8)
			{
				metadatas["genre"] = genre
			}
		}
		mpd_return_pair(_connection, tmpGenre)
		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || !mpd_response_finish(_connection))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
		}

		return metadatas
	}

	// MARK: - Play / Queue
	func playAlbum(_ album: Album, random: Bool, loop: Bool)
	{
		if let songs = album.songs
		{
			playTracks(songs, random: random, loop: loop)
		}
		else
		{
			if let songs = getSongsForAlbum(album)
			{
				playTracks(songs, random: random, loop: loop)
			}
		}
	}

	func playTracks(_ tracks: [Track], random: Bool, loop: Bool)
	{
		if !mpd_run_clear(_connection)
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return
		}

		setRandom(random)
		setRepeat(loop)

		for track in tracks
		{
			if !mpd_run_add(_connection, track.uri)
			{
				Logger.dlog(getErrorMessageForConnection(_connection!))
				return
			}
		}

		if !mpd_run_play_pos(_connection, random ? arc4random_uniform(UInt32(tracks.count)) : 0)
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
		}
	}
	
	func addAlbumToQueue(_ album: Album)
	{
		if let tracks = album.songs
		{
			for track in tracks
			{
				if !mpd_run_add(_connection, track.uri)
				{
					Logger.dlog(getErrorMessageForConnection(_connection!))
					return
				}
			}
		}
		else
		{
			if let tracks = getSongsForAlbum(album)
			{
				for track in tracks
				{
					if !mpd_run_add(_connection, track.uri)
					{
						Logger.dlog(getErrorMessageForConnection(_connection!))
						return
					}
				}
			}
		}
	}

	func togglePause() -> Bool
	{
		return mpd_run_toggle_pause(_connection)
	}

	func nextTrack()
	{
		if !mpd_run_next(_connection)
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
		}
	}

	func previousTrack()
	{
		if !mpd_run_previous(_connection)
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
		}
	}

	func setRandom(_ random: Bool)
	{
		if !mpd_run_random(_connection, random)
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
		}
	}

	func setRepeat(_ loop: Bool)
	{
		if !mpd_run_repeat(_connection, loop)
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
		}
	}

	func setTrackPosition(_ position: Int, trackPosition: UInt32)
	{
		if !mpd_run_seek_pos(_connection, trackPosition, UInt32(position))
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
		}
	}

	func setVolume(_ volume: UInt32)
	{
		if !mpd_run_set_volume(_connection, volume)
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
		}
	}

	// MARK: - Player status
	func getStatus()
	{
		let ret = mpd_run_status(_connection)
		if ret == nil
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
		}
	}

	func getPlayerInfos() -> [String : Any]?
	{
		let song = mpd_run_current_song(_connection)
		if song == nil
		{
			return nil
		}

		let status = mpd_run_status(_connection)
		if status == nil
		{
			Logger.dlog("[!] No status.")
			return nil
		}

		let elapsed = mpd_status_get_elapsed_time(status)
		guard let track = trackFromMPDSongObject(song!) else
		{
			return nil
		}
		let state = statusFromMPDStateObject(mpd_status_get_state(status)).rawValue
		let tmp = mpd_song_get_tag(song, MPD_TAG_ALBUM, 0)
		let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating:tmp!), count: Int(strlen(tmp)), deallocator: .none)
		if let name = String(data: dataTemp, encoding: .utf8)
		{
			if let album = delegate?.albumMatchingName(name)
			{
				return [kPlayerTrackKey : track, kPlayerAlbumKey : album, kPlayerElapsedKey : Int(elapsed), kPlayerStatusKey : state]
			}
		}

		Logger.dlog("[!] No matching album found.")
		return nil
	}

	// MARK: - Stats
	func getStats() -> [String : String]
	{
		let ret = mpd_run_stats(_connection)
		if ret == nil
		{
			Logger.dlog(getErrorMessageForConnection(_connection!))
			return [:]
		}

		let nalbums = mpd_stats_get_number_of_albums(ret)
		let nartists = mpd_stats_get_number_of_artists(ret)
		let nsongs = mpd_stats_get_number_of_songs(ret)
		let dbplaytime = mpd_stats_get_db_play_time(ret)
		let mpduptime = mpd_stats_get_uptime(ret)
		let mpdplaytime = mpd_stats_get_play_time(ret)
		let mpddbupdate = mpd_stats_get_db_update_time(ret)

		return ["albums" : String(nalbums), "artists" : String(nartists), "songs" : String(nsongs), "dbplaytime" : String(dbplaytime), "mpduptime" : String(mpduptime), "mpdplaytime" : String(mpdplaytime), "mpddbupdate" : String(mpddbupdate)]
	}

	// MARK: - Private
	private func getErrorMessageForConnection(_ connection: OpaquePointer) -> String
	{
		let err = mpd_connection_get_error_message(_connection)
		let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: err!), count: Int(strlen(err)), deallocator: .none)
		if let msg = String(data: dataTemp, encoding: .utf8)
		{
			return msg
		}
		return "NO ERROR MESSAGE"
	}

	private func trackFromMPDSongObject(_ song: OpaquePointer) -> Track?
	{
		// title
		var tmp = mpd_song_get_tag(song, MPD_TAG_TITLE, 0)
		let dataTemp1 = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: tmp!), count: Int(strlen(tmp)), deallocator: .none)
		guard let title = String(data: dataTemp1, encoding: .utf8) else
		{
			return nil
		}
		// artist
		tmp = mpd_song_get_tag(song, MPD_TAG_ARTIST, 0)
		let dataTemp2 = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: tmp!), count: Int(strlen(tmp)), deallocator: .none)
		guard let artist = String(data: dataTemp2, encoding: .utf8) else
		{
			return nil
		}
		// track number
		tmp = mpd_song_get_tag(song, MPD_TAG_TRACK, 0)
		let dataTemp3 = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: tmp!), count: Int(strlen(tmp)), deallocator: .none)
		guard var trackNumber = String(data: dataTemp3, encoding: .utf8) else
		{
			return nil
		}
		trackNumber = trackNumber.components(separatedBy: "/").first!
		// duration
		let duration = mpd_song_get_duration(song)
		// uri
		tmp = mpd_song_get_uri(song)
		let dataTemp4 = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: tmp!), count: Int(strlen(tmp)), deallocator: .none)
		guard let uri = String(data: dataTemp4, encoding: .utf8) else
		{
			return nil
		}
		// Position in the queue
		let pos = mpd_song_get_pos(song)

		// create track
		let trackNumInt = Int(trackNumber) ?? 1
		let track = Track(title: title, artist: artist, duration: Duration(seconds: UInt(duration)), trackNumber: trackNumInt, uri: uri)
		track.position = pos
		return track
	}

	private func statusFromMPDStateObject(_ state: mpd_state) -> PlayerStatus
	{
		switch state
		{
			case MPD_STATE_PLAY:
				return .playing
			case MPD_STATE_PAUSE:
				return .paused
			case MPD_STATE_STOP:
				return .stopped
			default:
				return .unknown
		}
	}

	private func mpdTagTypeFromDisplayType(_ displayType: DisplayType) -> mpd_tag_type
	{
		switch displayType
		{
			case .albums:
				return MPD_TAG_ALBUM
			case .genres:
				return MPD_TAG_GENRE
			case .artists:
				return MPD_TAG_ARTIST
		}
	}
}
