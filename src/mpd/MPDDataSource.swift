// MPDDataSource.swift
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
	private let _queue: dispatch_queue_t
	// Timer (1sec)
	private var _timer: dispatch_source_t!

	// MARK: - Initializers
	init()
	{
		self._queue = dispatch_queue_create("io.whine.mpdremote.queue.ds", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0))
	}

	// MARK: - Public
	func initialize() -> Bool
	{
		// Sanity check 1
		if self._mpdConnection != nil
		{
			if self._mpdConnection.connected
			{
				return true
			}
		}

		// Sanity check 2
		guard let server = self.server else
		{
			Logger.dlog("[!] Server object is nil")
			return false
		}

		// Connect
		self._mpdConnection = MPDConnection(server:server)
		let ret = self._mpdConnection.connect()
		if ret
		{
			self._mpdConnection.delegate = self
			self._startTimer(20.0)
		}
		else
		{
			self._mpdConnection = nil
		}
		return ret
	}

	func getListForDisplayType(displayType: DisplayType, callback: () -> Void)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue) {
			let list = self._mpdConnection.getListForDisplayType(displayType)
			let set = NSCharacterSet(charactersInString:".?!:;/+=-*'\"")
			switch (displayType)
			{
				case .Albums:
					self.albums = (list as! [Album]).sort({$0.name.stringByTrimmingCharactersInSet(set) < $1.name.stringByTrimmingCharactersInSet(set)})
				case .Genres:
					self.genres = (list as! [Genre]).sort({$0.name.stringByTrimmingCharactersInSet(set) < $1.name.stringByTrimmingCharactersInSet(set)})
				case .Artists:
					self.artists = (list as! [Artist]).sort({$0.name.stringByTrimmingCharactersInSet(set) < $1.name.stringByTrimmingCharactersInSet(set)})
			}
			callback()
		}
	}

	func getAlbumForGenre(genre: Genre, callback: () -> Void)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue) {
			if let album = self._mpdConnection.getAlbumForGenre(genre)
			{
				genre.albums.append(album)
			}
			callback()
		}
	}

	func getAlbumsForGenre(genre: Genre, callback: () -> Void)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue) {
			let albums = self._mpdConnection.getAlbumsForGenre(genre)
			genre.albums = albums
			callback()
		}
	}

	func getAlbumsForArtist(artist: Artist, callback: () -> Void)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue) {
			let list = self._mpdConnection.getAlbumsForArtist(artist)
			let set = NSCharacterSet(charactersInString:".?!:;/+=-*'\"")
			artist.albums = list.sort({$0.name.stringByTrimmingCharactersInSet(set) < $1.name.stringByTrimmingCharactersInSet(set)})
			callback()
		}
	}

	func getArtistsForGenre(genre: Genre, callback: ([Artist]) -> Void)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue) {
			let list = self._mpdConnection.getArtistsForGenre(genre)
			let set = NSCharacterSet(charactersInString:".?!:;/+=-*'\"")
			callback(list.sort({$0.name.stringByTrimmingCharactersInSet(set) < $1.name.stringByTrimmingCharactersInSet(set)}))
		}
	}

	func getPathForAlbum(album: Album, callback: () -> Void)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue) {
			album.path = self._mpdConnection.getPathForAlbum(album)
			callback()
		}
	}

	func getSongsForAlbum(album: Album, callback: () -> Void)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue) {
			album.songs = self._mpdConnection.getSongsForAlbum(album)
			callback()
		}
	}

	func getSongsForAlbums(albums: [Album], callback: () -> Void)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue) {
			for album in albums
			{
				album.songs = self._mpdConnection.getSongsForAlbum(album)
			}
			callback()
		}
	}

	func getMetadatasForAlbum(album: Album, callback: () -> Void)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue) {
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

	func getStats(callback: ([String : String]) -> Void)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue) {
			let stats = self._mpdConnection.getStats()
			callback(stats)
		}
	}

	// MARK: - Private
	private func _startTimer(interval: Double)
	{
		self._timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self._queue)
		dispatch_source_set_timer(self._timer, DISPATCH_TIME_NOW, UInt64(interval * Double(NSEC_PER_SEC)), UInt64(0.2 * Double(NSEC_PER_SEC))) // every interval seconds, with leeway of 0.2 second
		dispatch_source_set_event_handler(self._timer) {
			self._playerStatus()
		}
		dispatch_resume(self._timer)
	}

	private func _stopTimer()
	{
		dispatch_source_cancel(self._timer)
		self._timer = nil
	}

	private func _playerStatus()
	{
		self._mpdConnection.getStatus()
	}
}

extension MPDDataSource : MPDConnectionDelegate
{
	func albumMatchingName(name: String) -> Album?
	{
		let albums = MPDDataSource.shared.albums
		return albums.filter({$0.name == name}).first
	}
}
