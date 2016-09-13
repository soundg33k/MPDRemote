// MPDDataSource.swift
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


import UIKit


final class MPDDataSource
{
	// MARK: - Public properties
	// Singletion instance
	static let shared = MPDDataSource()
	// MPD server
	var server: MPDServer! = nil
	// Albums list
	private(set) var albums = [Album]()
	// Genres list
	private(set) var genres = [Genre]()
	// Artists list
	private(set) var artists = [Artist]()

	// MARK: - Private properties
	// MPD Connection
	private var _mpdConnection: MPDConnection! = nil
	// Serial queue for the connection
	private let _queue: DispatchQueue
	// Timer (1sec)
	private var _timer: DispatchSourceTimer!

	// MARK: - Initializers
	init()
	{
		self._queue = DispatchQueue(label:"io.whine.mpdremote.queue.ds", qos:.default, attributes:[], autoreleaseFrequency:.inherit, target: nil)
		//self._queue = DispatchQueue(label: "io.whine.mpdremote.queue.ds", attributes:[.serial, .qosDefault], target: nil)
	}

	// MARK: - Public
	func initialize() -> Bool
	{
		// Sanity check 1
		if _mpdConnection != nil
		{
			if _mpdConnection.connected
			{
				return true
			}
		}

		// Sanity check 2
		guard let server = server else
		{
			Logger.dlog("[!] Server object is nil")
			return false
		}

		// Connect
		_mpdConnection = MPDConnection(server:server)
		let ret = _mpdConnection.connect()
		if ret
		{
			_mpdConnection.delegate = self
			_startTimer(20)
		}
		else
		{
			_mpdConnection = nil
		}
		return ret
	}

	func getListForDisplayType(_ displayType: DisplayType, callback: @escaping () -> Void)
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}

		_queue.async {
			let list = self._mpdConnection.getListForDisplayType(displayType)
			let set = CharacterSet(charactersIn:".?!:;/+=-*'\"")
			switch (displayType)
			{
				case .albums:
					self.albums = (list as! [Album]).sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
				case .genres:
					self.genres = (list as! [Genre]).sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
				case .artists:
					self.artists = (list as! [Artist]).sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
			}
			callback()
		}
	}

	func getAlbumForGenre(_ genre: Genre, callback: @escaping () -> Void)
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}

		_queue.async {
			if let album = self._mpdConnection.getAlbumForGenre(genre)
			{
				genre.albums.append(album)
			}
			callback()
		}
	}

	func getAlbumsForGenre(_ genre: Genre, callback: @escaping () -> Void)
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}

		_queue.async {
			let albums = self._mpdConnection.getAlbumsForGenre(genre)
			genre.albums = albums
			callback()
		}
	}

	func getAlbumsForArtist(_ artist: Artist, callback: @escaping () -> Void)
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}

		_queue.async {
			let list = self._mpdConnection.getAlbumsForArtist(artist)
			let set = CharacterSet(charactersIn:".?!:;/+=-*'\"")
			artist.albums = list.sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)})
			callback()
		}
	}

	func getArtistsForGenre(_ genre: Genre, callback: @escaping ([Artist]) -> Void)
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}

		_queue.async {
			let list = self._mpdConnection.getArtistsForGenre(genre)
			let set = CharacterSet(charactersIn:".?!:;/+=-*'\"")
			callback(list.sorted(by: {$0.name.trimmingCharacters(in: set) < $1.name.trimmingCharacters(in: set)}))
		}
	}

	func getPathForAlbum(_ album: Album, callback: @escaping () -> Void)
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}

		_queue.async {
			album.path = self._mpdConnection.getPathForAlbum(album)
			callback()
		}
	}

	func getSongsForAlbum(_ album: Album, callback: @escaping () -> Void)
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}

		_queue.async {
			album.songs = self._mpdConnection.getSongsForAlbum(album)
			callback()
		}
	}

	func getSongsForAlbums(_ albums: [Album], callback: @escaping () -> Void)
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}

		_queue.async {
			for album in albums
			{
				album.songs = self._mpdConnection.getSongsForAlbum(album)
			}
			callback()
		}
	}

	func getMetadatasForAlbum(_ album: Album, callback: @escaping () -> Void)
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}

		_queue.async {
			let metadatas = self._mpdConnection.getMetadatasForAlbum(album)
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
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}

		_queue.async {
			let stats = self._mpdConnection.getStats()
			callback(stats)
		}
	}

	// MARK: - Private
	private func _startTimer(_ interval: Int)
	{
		_timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: _queue)
		_timer.scheduleRepeating(deadline: .now(), interval:.seconds(interval))
		_timer.setEventHandler {
			self._playerStatus()
		}
		_timer.resume()
	}

	private func _stopTimer()
	{
		_timer.cancel()
		_timer = nil
	}

	private func _playerStatus()
	{
		_mpdConnection.getStatus()
	}
}

extension MPDDataSource : MPDConnectionDelegate
{
	func albumMatchingName(_ name: String) -> Album?
	{
		let albums = MPDDataSource.shared.albums
		return albums.filter({$0.name == name}).first
	}
}
