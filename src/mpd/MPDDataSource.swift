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


final class MPDDataSource : MPDConnectionDelegate
{
	// MARK: - Public properties
	// Singletion instance
	static let shared = MPDDataSource()
	// MPD server
	var server: MPDServer! = nil
	// Albums list
	private(set) var albums = [Album]()

	// MARK: - Private properties
	// MPD Connection
	private var _mpdConnection: MPDConnection! = nil
	// Serial queue for the connection
	private let _queue: dispatch_queue_t

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
		}
		else
		{
			self._mpdConnection = nil
		}
		return ret
	}

	func fill(callback: () -> Void)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue, {
			let list = self._mpdConnection.getAlbumsList()
			let set = NSCharacterSet(charactersInString:".?!:;/+=-*'\"")
			self.albums = list.sort({$0.name.stringByTrimmingCharactersInSet(set) < $1.name.stringByTrimmingCharactersInSet(set)})
			callback()
		})
	}

	func findCoverPathForAlbum(album: Album, callback: () -> Void)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue, {
			self._mpdConnection.findCoverForAlbum(album)
			callback()
		})
	}

	func getSongsForAlbum(album: Album, callback: () -> Void)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue, {
			album.songs = self._mpdConnection.getSongsForAlbum(album)
			callback()
		})
	}

	func getMetadatasForAlbum(album: Album, callback: () -> Void)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}
		
		dispatch_async(self._queue, {
			self._mpdConnection.getMetadatasForAlbum(album)
			callback()
		})
	}
}
