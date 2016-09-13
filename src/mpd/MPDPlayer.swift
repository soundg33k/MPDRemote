// MPDPlayer.swift
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


import Foundation


enum PlayerStatus : Int
{
	case playing
	case paused
	case stopped
	case unknown
}


final class MPDPlayer
{
	// MARK: - Public properties
	// Singletion instance
	static let shared = MPDPlayer()
	// MPD server
	var server: MPDServer! = nil
	// Player status (playing, paused, stopped)
	private(set) var status: PlayerStatus = .unknown
	// Current playing track
	private(set) var currentTrack: Track? = nil
	// Current playing album
	private(set) var currentAlbum: Album? = nil

	// MARK: - Private properties
	// MPD Connection
	private var _mpdConnection: MPDConnection! = nil
	// Internal queue
	private let _queue: DispatchQueue
	// Timer (1sec)
	private var _timer: DispatchSourceTimer!

	// MARK: - Initializers
	init()
	{
		self._queue = DispatchQueue(label: "io.whine.mpdremote.queue.player", qos: .default, attributes: [], autoreleaseFrequency: .inherit, target: nil)
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
			_startTimer(1)
		}
		else
		{
			_mpdConnection = nil
		}
		return ret
	}

	// MARK: - Playing
	func playAlbum(_ album: Album, random: Bool, loop: Bool)
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}
		
		_queue.async {
			self._mpdConnection.playAlbum(album, random:random, loop:loop)
		}
	}

	func playTracks(_ tracks: [Track], random: Bool, loop: Bool)
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}

		_queue.async {
			self._mpdConnection.playTracks(tracks, random:random, loop:loop)
		}
	}

	// MARK: - Pausing
	@objc func togglePause()
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}
		
		_queue.async {
			_ = self._mpdConnection.togglePause()
		}
	}

	// MARK: - Add to queue
	func addAlbumToQueue(_ album: Album)
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}
		
		_queue.async {
			self._mpdConnection.addAlbumToQueue(album)
		}
	}

	// MARK: - Repeat
	func setRepeat(_ loop: Bool)
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}

		_queue.async {
			self._mpdConnection.setRepeat(loop)
		}
	}

	// MARK: - Random
	func setRandom(_ random: Bool)
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}

		_queue.async {
			self._mpdConnection.setRandom(random)
		}
	}

	// MARK: - Tracks navigation
	@objc func requestNextTrack()
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}

		_queue.async {
			self._mpdConnection.nextTrack()
		}
	}

	@objc func requestPreviousTrack()
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}

		_queue.async {
			self._mpdConnection.previousTrack()
		}
	}

	// MARK: - Track position
	func setTrackPosition(_ position: Int, trackPosition: UInt32)
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}

		_queue.async {
			self._mpdConnection.setTrackPosition(position, trackPosition:trackPosition)
		}
	}

	// MARK: - Volume
	func setVolume(_ volume: Int)
	{
		if _mpdConnection == nil || !_mpdConnection.connected
		{
			return
		}

		_queue.async {
			self._mpdConnection.setVolume(UInt32(volume))
		}
	}

	// MARK: - Private
	private func _startTimer(_ interval: Int)
	{
		_timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: _queue)
		_timer.scheduleRepeating(deadline: .now(), interval:.seconds(interval))
		_timer.setEventHandler {
			self._playerInformations()
		}
		_timer.resume()
	}

	private func _stopTimer()
	{
		_timer.cancel()
		_timer = nil
	}

	private func _playerInformations()
	{
		guard let infos = _mpdConnection.getPlayerInfos() else {return}
		let status = PlayerStatus(rawValue:infos[kPlayerStatusKey] as! Int)!
		let track = infos[kPlayerTrackKey] as! Track
		let album = infos[kPlayerAlbumKey] as! Album

		// Track changed
		if currentTrack == nil || (currentTrack != nil && track != currentTrack!)
		{
			DispatchQueue.main.async {
				NotificationCenter.default.post(name: .playingTrackChanged, object:nil, userInfo:infos)
			}
		}

		// Status changed
		if status != status
		{
			DispatchQueue.main.async {
				NotificationCenter.default.post(name: .playerStatusChanged, object:nil, userInfo:infos)
			}
		}

		self.status = status
		currentTrack = track
		currentAlbum = album
		DispatchQueue.main.async {
			NotificationCenter.default.post(name: .currentPlayingTrack, object:nil, userInfo:infos)
		}
	}
}

extension MPDPlayer : MPDConnectionDelegate
{
	func albumMatchingName(_ name: String) -> Album?
	{
		let albums = MPDDataSource.shared.albums
		return albums.filter({$0.name == name}).first
	}
}
