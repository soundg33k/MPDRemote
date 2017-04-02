// MusicDataSource.swift
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


import Foundation


final class MusicDataSource
{
	// MARK: - Public properties
	// Singletion instance
	static let shared = MusicDataSource()
	// MPD server
	var server: AudioServer! = nil
	// Selected display type
	private(set) var displayType = DisplayType.albums
	// Albums list
	private(set) var albums = [Album]()
	// Genres list
	private(set) var genres = [Genre]()
	// Artists list
	private(set) var artists = [Artist]()
	// Playlists list
	private(set) var playlists = [Playlist]()

	// MARK: - Private properties
	// MPD Connection
	private var _connection: AudioServerConnection! = nil
	// Serial queue for the connection
	private let _queue: DispatchQueue
	// Timer (1sec)
	private var _timer: DispatchSourceTimer!

	// MARK: - Initializers
	init()
	{
		self._queue = DispatchQueue(label: "io.whine.mpdremote.queue.datasource", qos: .default, attributes: [], autoreleaseFrequency: .inherit, target:  nil)

		NotificationCenter.default.addObserver(self, selector: #selector(audioServerConfigurationDidChange(_:)), name: .audioServerConfigurationDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: .UIApplicationDidEnterBackground, object:nil)
		NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object:nil)
	}

	// MARK: - Public
	func initialize() -> Bool
	{
		// Sanity check 1
		if _connection != nil && _connection.isConnected
		{
			return true
		}

		// Sanity check 2
		guard let server = server else
		{
			Logger.dlog("[!] Server object is nil")
			return false
		}

		// Connect
		_connection = MPDConnection(server)
		let ret = _connection.connect()
		if ret
		{
			_connection.delegate = self
			startTimer(20)
		}
		else
		{
			_connection = nil
		}
		return ret
	}

	func deinitialize()
	{
		stopTimer()
		if _connection != nil
		{
			_connection.delegate = nil
			_connection.disconnect()
			_connection = nil
		}
	}

	func reinitialize() -> Bool
	{
		deinitialize()
		return initialize()
	}

	func selectedList() -> [MusicalEntity]
	{
		switch displayType
		{
			case .albums:
				return albums
			case .genres:
				return genres
			case .artists:
				return artists
			case .playlists:
				return playlists
		}
	}

	func getListForDisplayType(_ displayType: DisplayType, callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		self.displayType = displayType

		_queue.async {
			let list = self._connection.getListForDisplayType(displayType)
			let set = CharacterSet(charactersIn: ".?!:;/+=-*'\"")
			switch (displayType)
			{
				case .albums:
					self.albums = (list as! [Album]).sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
				case .genres:
					self.genres = (list as! [Genre]).sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
				case .artists:
					self.artists = (list as! [Artist]).sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
				case .playlists:
					self.playlists = (list as! [Playlist]).sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
			}
			callback()
		}
	}

	func getAlbumForGenre(_ genre: Genre, callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			if let album = self._connection.getAlbumForGenre(genre)
			{
				genre.albums.append(album)
			}
			callback()
		}
	}

	func getAlbumsForGenre(_ genre: Genre, callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			let albums = self._connection.getAlbumsForGenre(genre)
			genre.albums = albums
			callback()
		}
	}

	func getAlbumsForArtist(_ artist: Artist, callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			let list = self._connection.getAlbumsForArtist(artist)
			let set = CharacterSet(charactersIn: ".?!:;/+=-*'\"")
			artist.albums = list.sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
			callback()
		}
	}

	func getArtistsForGenre(_ genre: Genre, callback: @escaping ([Artist]) -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			let list = self._connection.getArtistsForGenre(genre)
			let set = CharacterSet(charactersIn: ".?!:;/+=-*'\"")
			callback(list.sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)}))
		}
	}

	func getPathForAlbum(_ album: Album, callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			album.path = self._connection.getPathForAlbum(album)
			callback()
		}
	}

	func getTracksForAlbum(_ album: Album, callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			album.tracks = self._connection.getTracksForAlbum(album)
			callback()
		}
	}

	func getTracksForAlbums(_ albums: [Album], callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			for album in albums
			{
				album.tracks = self._connection.getTracksForAlbum(album)
			}
			callback()
		}
	}

	func getTracksForPlaylist(_ playlist: Playlist, callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			playlist.tracks = self._connection.getTracksForPlaylist(playlist)
			callback()
		}
	}

	func getMetadatasForAlbum(_ album: Album, callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			let metadatas = self._connection.getMetadatasForAlbum(album)
			if let artist = metadatas["artist"] as! String?
			{
				album.artist = artist
			}
			if let year = metadatas["year"] as! String?
			{
				album.year = year
			}
			if let genre = metadatas["genre"] as! String?
			{
				album.genre = genre
			}
			callback()
		}
	}

	func getStats(_ callback: @escaping ([String : String]) -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			let stats = self._connection.getStats()
			callback(stats)
		}
	}

	func currentCollection(_ displayType: DisplayType) -> [MusicalEntity]
	{
		switch (displayType)
		{
			case .albums:
				return albums
			case .genres:
				return genres
			case .artists:
				return artists
			case .playlists:
				return playlists
		}
	}

	// MARK: - Private
	private func startTimer(_ interval: Int)
	{
		_timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: _queue)
		_timer.scheduleRepeating(deadline: .now(), interval: .seconds(interval))
		_timer.setEventHandler {
			self.getlayerStatus()
		}
		_timer.resume()
	}

	private func stopTimer()
	{
		if let _ = _timer
		{
			_timer.cancel()
			_timer = nil
		}
	}

	private func getlayerStatus()
	{
		_connection.getStatus()
	}

	// MARK: - Notifications
	@objc func audioServerConfigurationDidChange(_ aNotification: Notification)
	{
		if let server = aNotification.object as? AudioServer
		{
			self.server = server
			_ = self.reinitialize()
		}
	}

	@objc func applicationDidEnterBackground(_ aNotification: Notification)
	{
		deinitialize()
	}

	@objc func applicationWillEnterForeground(_ aNotification: Notification)
	{
		_ = reinitialize()
	}
}

extension MusicDataSource : AudioServerConnectionDelegate
{
	func albumMatchingName(_ name: String) -> Album?
	{
		let albums = MusicDataSource.shared.albums
		return albums.filter({$0.name == name}).first
	}
}
