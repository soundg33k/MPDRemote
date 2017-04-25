// MPDConnection.swift
// Copyright (c) 2017 Nyx0uf
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
	private(set) var isConnected = false

	// MARK: - Private properties
	// mpd_connection object
	private var _connection: OpaquePointer? = nil
	// Timeout in seconds
	private let _timeout = UInt32(10)

	// MARK: - Initializers
	init(_ server: AudioServer)
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
			Logger.dlog(getLastErrorMessageForConnection())
			_connection = nil
			return false
		}

		// Set password if needed
		if server.password.length > 0
		{
			if mpd_run_password(_connection, server.password) == false
			{
				Logger.dlog(getLastErrorMessageForConnection())
				mpd_connection_free(_connection)
				_connection = nil
				return false
			}
		}

		isConnected = true
		return true
	}

	func disconnect()
	{
		if _connection != nil
		{
			mpd_connection_free(_connection)
			_connection = nil
		}
		isConnected = false
	}

	// MARK: - Get infos about tracks / albums / etc…
	func getListForDisplayType(_ displayType: DisplayType) -> [MusicalEntity]
	{
		if displayType == .playlists
		{
			return self.getPlaylists()
		}

		let tagType = mpdTagTypeFromDisplayType(displayType)

		var list = [MusicalEntity]()
		if (mpd_search_db_tags(_connection, tagType) == false || mpd_search_commit(_connection) == false)
		{
			Logger.dlog(getLastErrorMessageForConnection())
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
					case .playlists:
						Logger.dlog("impossible")
				}
			}

			mpd_return_pair(_connection, pair)
			pair = mpd_recv_pair_tag(_connection, tagType)
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}

		return list
	}

	func getAlbumForGenre(_ genre: Genre) -> Album?
	{
		if mpd_search_db_tags(_connection, MPD_TAG_ALBUM) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return nil
		}
		if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_GENRE, genre.name) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return nil
		}
		if mpd_search_commit(_connection) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return nil
		}

		guard let pair = mpd_recv_pair_tag(_connection, MPD_TAG_ALBUM) else
		{
			Logger.dlog("[!] No pair.")
			return nil
		}

		let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: (pair.pointee.value)!), count: Int(strlen(pair.pointee.value)), deallocator: .none)
		guard let name = String(data: dataTemp, encoding: .utf8) else
		{
			Logger.dlog("[!] Invalid name.")
			mpd_return_pair(_connection, pair)
			return nil
		}
		mpd_return_pair(_connection, pair)

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}

		return Album(name: name)
	}

	func getAlbumsForGenre(_ genre: Genre) -> [Album]
	{
		var list = [Album]()

		if mpd_search_db_tags(_connection, MPD_TAG_ALBUM) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return list
		}
		if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_GENRE, genre.name) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return list
		}
		if mpd_search_commit(_connection) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
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

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}

		return list
	}

	func getAlbumsForArtist(_ artist: Artist) -> [Album]
	{
		var list = [Album]()

		if mpd_search_db_tags(_connection, MPD_TAG_ALBUM) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return list
		}
		if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ARTIST, artist.name) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return list
		}
		if mpd_search_commit(_connection) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
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

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}

		return list
	}

	func getArtistsForGenre(_ genre: Genre) -> [Artist]
	{
		var list = [Artist]()

		if mpd_search_db_tags(_connection, MPD_TAG_ARTIST) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return list
		}
		if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_GENRE, genre.name) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return list
		}
		if mpd_search_commit(_connection) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
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

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}

		return list
	}

	func getPathForAlbum(_ album: Album) -> String?
	{
		var path: String? = nil
		if mpd_search_db_songs(_connection, true) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return path
		}
		if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return path
		}
		if mpd_search_commit(_connection) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return path
		}

		if let song = mpd_recv_song(_connection)
		{
			if let uri = mpd_song_get_uri(song)
			{
				let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: uri), count: Int(strlen(uri)), deallocator: .none)
				if let name = String(data: dataTemp, encoding: .utf8)
				{
					path = URL(fileURLWithPath: name).deletingLastPathComponent().path
				}
			}
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}

		return path
	}

	func getTracksForAlbum(_ album: Album) -> [Track]?
	{
		if mpd_search_db_songs(_connection, true) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return nil
		}
		if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return nil
		}
		if album.artist.length > 0
		{
			if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM_ARTIST, album.artist) == false
			{
				Logger.dlog(getLastErrorMessageForConnection())
				return nil
			}
		}
		if mpd_search_commit(_connection) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
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

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}

		return list
	}

	func getTracksForPlaylist(_ playlist: Playlist) -> [Track]?
	{
		if mpd_send_list_playlist(_connection, playlist.name) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return nil
		}

		var list = [Track]()
		var entity = mpd_recv_entity(_connection)
		var trackNumber = 1
		while entity != nil
		{
			if let song = mpd_entity_get_song(entity)
			{
				if let track = trackFromMPDSongObject(song)
				{
					track.trackNumber = trackNumber
					list.append(track)
					trackNumber += 1
				}
			}
			entity = mpd_recv_entity(_connection)
		}

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}

		for track in list
		{
			if mpd_search_db_songs(_connection, true) == false
			{
				Logger.dlog(getLastErrorMessageForConnection())
				continue
			}
			if mpd_search_add_uri_constraint(_connection, MPD_OPERATOR_DEFAULT, track.uri) == false
			{
				Logger.dlog(getLastErrorMessageForConnection())
				continue
			}

			if mpd_search_commit(_connection) == false
			{
				Logger.dlog(getLastErrorMessageForConnection())
				continue
			}

			var song = mpd_recv_song(_connection)
			while song != nil
			{
				if let t = trackFromMPDSongObject(song!)
				{
					track.artist = t.artist
					track.duration = t.duration
					track.position = t.position
					track.name = t.name
				}
				song = mpd_recv_song(_connection)
			}

			if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
			{
				Logger.dlog(getLastErrorMessageForConnection())
			}
		}

		return list
	}

	func getMetadatasForAlbum(_ album: Album) -> [String : Any]
	{
		var metadatas = [String : Any]()
		// Find album artist
		if mpd_search_db_tags(_connection, MPD_TAG_ALBUM_ARTIST) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return metadatas
		}
		if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return metadatas
		}
		if mpd_search_commit(_connection) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
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
		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return metadatas
		}

		// Find album year
		if mpd_search_db_tags(_connection, MPD_TAG_DATE) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return metadatas
		}
		if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return metadatas
		}
		if mpd_search_commit(_connection) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
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
		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return metadatas
		}

		// Find album genre
		if mpd_search_db_tags(_connection, MPD_TAG_GENRE) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return metadatas
		}
		if mpd_search_add_tag_constraint(_connection, MPD_OPERATOR_DEFAULT, MPD_TAG_ALBUM, album.name) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return metadatas
		}
		if mpd_search_commit(_connection) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
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
		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}

		return metadatas
	}

	// MARK: - Playlists
	func getPlaylists() -> [Playlist]
	{
		if mpd_send_list_playlists(_connection) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return []
		}

		var list = [Playlist]()
		var playlist = mpd_recv_playlist(_connection)
		while playlist != nil
		{
			if let tmpPath = mpd_playlist_get_path(playlist)
			{
				if let name = String(cString: tmpPath, encoding: .utf8)
				{
					list.append(Playlist(name: name))
				}
			}

			playlist = mpd_recv_playlist(_connection)
		}

		return list
	}

	func getSongsOfCurrentQueue() -> [Track]
	{
		if mpd_send_list_queue_meta(_connection) == false
		{
			return []
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

		if (mpd_connection_get_error(_connection) != MPD_ERROR_SUCCESS || mpd_response_finish(_connection) == false)
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return []
		}

		return list
	}

	// MARK: - Play / Queue
	func playAlbum(_ album: Album, shuffle: Bool, loop: Bool)
	{
		if let songs = album.tracks
		{
			playTracks(songs, shuffle: shuffle, loop: loop)
		}
		else
		{
			if let songs = getTracksForAlbum(album)
			{
				playTracks(songs, shuffle: shuffle, loop: loop)
			}
		}
	}

	func playTracks(_ tracks: [Track], shuffle: Bool, loop: Bool)
	{
		if mpd_run_clear(_connection) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return
		}

		setRandom(shuffle)
		setRepeat(loop)

		for track in tracks
		{
			if mpd_run_add(_connection, track.uri) == false
			{
				Logger.dlog(getLastErrorMessageForConnection())
				return
			}
		}

		if mpd_run_play_pos(_connection, shuffle ? arc4random_uniform(UInt32(tracks.count)) : 0) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}
	}

	func playPlaylist(_ playlist: Playlist, shuffle: Bool, loop: Bool, position: UInt32 = 0)
	{
		if mpd_run_clear(_connection) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return
		}

		setRandom(shuffle)
		setRepeat(loop)

		if mpd_run_load(_connection, playlist.name) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
			return
		}

		if mpd_run_play_pos(_connection, UInt32(position)) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}
	}

	func playTrackAtPosition(_ position: UInt32)
	{
		if mpd_run_play_pos(_connection, position) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}
	}
	
	func addAlbumToQueue(_ album: Album)
	{
		if let tracks = album.tracks
		{
			for track in tracks
			{
				if mpd_run_add(_connection, track.uri) == false
				{
					Logger.dlog(getLastErrorMessageForConnection())
					return
				}
			}
		}
		else
		{
			if let tracks = getTracksForAlbum(album)
			{
				for track in tracks
				{
					if mpd_run_add(_connection, track.uri) == false
					{
						Logger.dlog(getLastErrorMessageForConnection())
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
		if mpd_run_next(_connection) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}
	}

	func previousTrack()
	{
		if mpd_run_previous(_connection) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}
	}

	func setRandom(_ random: Bool)
	{
		if mpd_run_random(_connection, random) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}
	}

	func setRepeat(_ loop: Bool)
	{
		if mpd_run_repeat(_connection, loop) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}
	}

	func setTrackPosition(_ position: Int, trackPosition: UInt32)
	{
		if mpd_run_seek_pos(_connection, trackPosition, UInt32(position)) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}
	}

	func setVolume(_ volume: UInt32)
	{
		if mpd_run_set_volume(_connection, volume) == false
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}
	}

	func getVolume() -> Int
	{
		guard let status = mpd_run_status(_connection) else
		{
			Logger.dlog("[!] Error getting status: \(getLastErrorMessageForConnection())")
			return 100
		}

		return Int(mpd_status_get_volume(status))
	}

	// MARK: - Player status
	func getStatus()
	{
		if mpd_run_status(_connection) == nil
		{
			Logger.dlog(getLastErrorMessageForConnection())
		}
	}

	func getPlayerInfos() -> [String : Any]?
	{
		guard let song = mpd_run_current_song(_connection) else
		{
			//Logger.dlog("[!] No song is currently being played.")
			return nil
		}

		guard let status = mpd_run_status(_connection) else
		{
			Logger.dlog("[!] Error getting status: \(getLastErrorMessageForConnection())")
			return nil
		}

		guard let track = trackFromMPDSongObject(song) else
		{
			Logger.dlog("[!] Error getting track: \(getLastErrorMessageForConnection())")
			return nil
		}
		let state = statusFromMPDStateObject(mpd_status_get_state(status)).rawValue
		let elapsed = mpd_status_get_elapsed_time(status)
		let volume = Int(mpd_status_get_volume(status))
		guard let tmpAlbumName = mpd_song_get_tag(song, MPD_TAG_ALBUM, 0) else
		{
			Logger.dlog("[!] Error getting album: \(getLastErrorMessageForConnection())")
			return nil
		}
		let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating:tmpAlbumName), count: Int(strlen(tmpAlbumName)), deallocator: .none)
		if let name = String(data: dataTemp, encoding: .utf8)
		{
			if let album = delegate?.albumMatchingName(name)
			{
				return [kPlayerTrackKey : track, kPlayerAlbumKey : album, kPlayerElapsedKey : Int(elapsed), kPlayerStatusKey : state, kPlayerVolumeKey : volume]
			}
		}

		Logger.dlog("[!] No matching album found.")
		return nil
	}

	// MARK: - Outputs
	func getAvailableOutputs() -> [AudioOutput]
	{
		if mpd_send_outputs(_connection) == false
		{
			return []
		}

		var ret = [AudioOutput]()
		var output = mpd_recv_output(_connection)
		while output != nil
		{
			guard let tmpName = mpd_output_get_name(output) else
			{
				mpd_output_free(output)
				continue
			}

			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: tmpName), count: Int(strlen(tmpName)), deallocator: .none)
			guard let name = String(data: dataTemp, encoding: .utf8) else
			{
				mpd_output_free(output)
				continue
			}

			let id = Int(mpd_output_get_id(output))

			let o = AudioOutput(id: id, name: name, enabled: mpd_output_get_enabled(output))
			ret.append(o)
			mpd_output_free(output)
			output = mpd_recv_output(_connection)
		}

		return ret
	}

	func toggleOutput(output: AudioOutput) -> Bool
	{
		if output.enabled
		{
			return mpd_run_disable_output(_connection, UInt32(output.id))
		}
		else
		{
			return mpd_run_enable_output(_connection, UInt32(output.id))
		}
	}

	// MARK: - Stats
	func getStats() -> [String : String]
	{
		guard let ret = mpd_run_stats(_connection) else
		{
			Logger.dlog(getLastErrorMessageForConnection())
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
	private func getLastErrorMessageForConnection() -> String
	{
		if _connection == nil
		{
			return "NO CONNECTION OBJECT"
		}

		if let errorMessage = mpd_connection_get_error_message(_connection)
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: errorMessage), count: Int(strlen(errorMessage)), deallocator: .none)
			if let msg = String(data: dataTemp, encoding: .utf8)
			{
				return msg
			}
		}

		return "NO ERROR MESSAGE"
	}

	private func trackFromMPDSongObject(_ song: OpaquePointer) -> Track?
	{
		// URI, should always be available?
		guard let tmpURI = mpd_song_get_uri(song) else
		{
			return nil
		}
		let dataTmp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: tmpURI), count: Int(strlen(tmpURI)), deallocator: .none)
		guard let uri = String(data: dataTmp, encoding: .utf8) else
		{
			return nil
		}
		// title
		var title = ""
		if let tmpPtr = mpd_song_get_tag(song, MPD_TAG_TITLE, 0)
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: tmpPtr), count: Int(strlen(tmpPtr)), deallocator: .none)
			let tmpString = String(data: dataTemp, encoding: .utf8)
			title = tmpString ?? ""
		}
		else
		{
			let bla = uri.components(separatedBy: "/")
			if let filename = bla.last
			{
				if let f = filename.components(separatedBy: ".").first
				{
					title = f
				}
			}
		}
		// artist
		var artist = ""
		if let tmpPtr = mpd_song_get_tag(song, MPD_TAG_ARTIST, 0)
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: tmpPtr), count: Int(strlen(tmpPtr)), deallocator: .none)
			let tmpString = String(data: dataTemp, encoding: .utf8)
			artist = tmpString ?? ""
		}
		// track number
		var trackNumber = "0"
		if let tmpPtr = mpd_song_get_tag(song, MPD_TAG_TRACK, 0)
		{
			let dataTemp = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: tmpPtr), count: Int(strlen(tmpPtr)), deallocator: .none)
			if let tmpString = String(data: dataTemp, encoding: .utf8)
			{
				if let number = tmpString.components(separatedBy: "/").first
				{
					trackNumber = number
				}
			}
		}
		// duration
		let duration = mpd_song_get_duration(song)
		// Position in the queue
		let pos = mpd_song_get_pos(song)

		// create track
		let trackNumInt = Int(trackNumber) ?? 1
		let track = Track(name: title, artist: artist, duration: Duration(seconds: UInt(duration)), trackNumber: trackNumInt, uri: uri)
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
			case .playlists:
				return MPD_TAG_UNKNOWN
		}
	}
}
