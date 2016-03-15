// MPDPlayer.swift
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


import Foundation


enum PlayerStatus : Int
{
	case Playing
	case Paused
	case Stopped
	case Unknown
}


final class MPDPlayer
{
	// MARK: - Public properties
	// Singletion instance
	static let shared = MPDPlayer()
	// MPD server
	var server: MPDServer! = nil
	// Player status (playing, paused, stopped)
	private(set) var status: PlayerStatus = .Unknown
	// Current playing track
	private(set) var currentTrack: Track? = nil
	// Current playing album
	private(set) var currentAlbum: Album? = nil

	// MARK: - Private properties
	// MPD Connection
	private var _mpdConnection: MPDConnection! = nil
	// Internal queue
	private let _queue: dispatch_queue_t
	// Timer (1sec)
	private var _timer: dispatch_source_t!

	// MARK: - Initializers
	init()
	{
		self._queue = dispatch_queue_create("io.whine.mpdremote.queue.player", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0))
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
			self._startTimer(1.0)
		}
		else
		{
			self._mpdConnection = nil
		}
		return ret
	}

	func playAlbum(album: Album, random: Bool, loop: Bool)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}
		
		dispatch_async(self._queue, {
			self._mpdConnection.playAlbum(album, random:random, loop:loop)
		})
	}

	func playTracks(tracks: [Track], random: Bool, loop: Bool)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue, {
			self._mpdConnection.playTracks(tracks, random:random, loop:loop)
		})
	}

	func addAlbumToQueue(album: Album)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue, {
			self._mpdConnection.addAlbumToQueue(album)
		})
	}

	func togglePausePlayback()
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue, {
			self._mpdConnection.togglePause()
		})
	}

	func pausePlayback()
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue, {
			self._mpdConnection.pausePlayback()
		})
	}

	func runPlayback()
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue, {
			self._mpdConnection.runPlayback()
		})
	}

	func setRepeat(loop: Bool)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue, {
			self._mpdConnection.setRepeat(loop)
		})
	}

	func setRandom(random: Bool)
	{
		if self._mpdConnection == nil || !self._mpdConnection.connected
		{
			return
		}

		dispatch_async(self._queue, {
			self._mpdConnection.setRandom(random)
		})
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
		guard let infos = self._mpdConnection.getPlayerStatus() else {return}
		let status = PlayerStatus(rawValue:infos[kPlayerStatusKey] as! Int)!
		let track = infos[kPlayerTrackKey] as! Track!
		let album = infos[kPlayerAlbumKey] as! Album!

		// Track changed
		if self.currentTrack == nil || (self.currentTrack != nil && track != self.currentTrack!)
		{
			dispatch_async(dispatch_get_main_queue(), {
				NSNotificationCenter.defaultCenter().postNotificationName(kNYXNotificationCurrentPlayingTrackChanged, object:nil, userInfo:infos)
			})
		}

		// Status changed
		if status != self.status
		{
			dispatch_async(dispatch_get_main_queue(), {
				NSNotificationCenter.defaultCenter().postNotificationName(kNYXNotificationPlayerStatusChanged, object:nil, userInfo:infos)
			})
		}

		self.status = status
		self.currentTrack = track
		self.currentAlbum = album
		dispatch_async(dispatch_get_main_queue(), {
			NSNotificationCenter.defaultCenter().postNotificationName(kNYXNotificationCurrentPlayingTrack, object:nil, userInfo:infos)
		})
	}
}

extension MPDPlayer : MPDConnectionDelegate
{
	@objc func albumMatchingName(name: String) -> Album?
	{
		let albums = MPDDataSource.shared.albums
		return albums.filter({$0.name == name}).first
	}
}
