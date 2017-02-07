// PlayerController.swift
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


final class PlayerController
{
	// MARK: - Public properties
	// Singletion instance
	static let shared = PlayerController()
	// MPD server
	var server: AudioServer! = nil
	// Player status (playing, paused, stopped)
	private(set) var currentStatus: PlayerStatus = .unknown
	// Current playing track
	private(set) var currentTrack: Track? = nil
	// Current playing album
	private(set) var currentAlbum: Album? = nil

	// MARK: - Private properties
	// MPD Connection
	private var _connection: AudioServerConnection! = nil
	// Internal queue
	private let _queue: DispatchQueue
	// Timer (1sec)
	private var _timer: DispatchSourceTimer!

	// MARK: - Initializers
	init()
	{
		self._queue = DispatchQueue(label: "io.whine.mpdremote.queue.player", qos: .default, attributes: [], autoreleaseFrequency: .inherit, target: nil)

		NotificationCenter.default.addObserver(self, selector: #selector(audioServerConfigurationDidChange(_:)), name: .audioServerConfigurationDidChange, object:nil)
		NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: .UIApplicationDidEnterBackground, object:nil)
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
			startTimer(500)
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

	// MARK: - Playing
	func playAlbum(_ album: Album, shuffle: Bool, loop: Bool)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			self._connection.playAlbum(album, shuffle: shuffle, loop: loop)
		}
	}

	func playTracks(_ tracks: [Track], shuffle: Bool, loop: Bool)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			self._connection.playTracks(tracks, shuffle: shuffle, loop: loop)
		}
	}

	func playPlaylist(_ playlist: Playlist, shuffle: Bool, loop: Bool, position: UInt32 = 0)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			self._connection.playPlaylist(playlist, shuffle: shuffle, loop: loop, position: position)
		}
	}

	// MARK: - Pausing
	@objc func togglePause()
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			_ = self._connection.togglePause()
		}
	}

	// MARK: - Add to queue
	func addAlbumToQueue(_ album: Album)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			self._connection.addAlbumToQueue(album)
		}
	}

	// MARK: - Repeat
	func setRepeat(_ loop: Bool)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			self._connection.setRepeat(loop)
		}
	}

	// MARK: - Random
	func setRandom(_ random: Bool)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			self._connection.setRandom(random)
		}
	}

	// MARK: - Tracks navigation
	@objc func requestNextTrack()
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			self._connection.nextTrack()
		}
	}

	@objc func requestPreviousTrack()
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			self._connection.previousTrack()
		}
	}

	// MARK: - Track position
	func setTrackPosition(_ position: Int, trackPosition: UInt32)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			self._connection.setTrackPosition(position, trackPosition: trackPosition)
		}
	}

	// MARK: - Volume
	func setVolume(_ volume: Int)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			self._connection.setVolume(UInt32(volume))
		}
	}

	func getVolume(callback: @escaping (Int) -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			let volume = self._connection.getVolume()
			callback(volume)
		}
	}

	// MARK: - Private
	private func startTimer(_ interval: Int)
	{
		_timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: _queue)
		_timer.scheduleRepeating(deadline: .now(), interval: .milliseconds(interval))
		_timer.setEventHandler {
			self.playerInformations()
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

	private func playerInformations()
	{
		guard let infos = _connection.getPlayerInfos() else {return}
		let status = infos[kPlayerStatusKey] as! Int
		let track = infos[kPlayerTrackKey] as! Track
		let album = infos[kPlayerAlbumKey] as! Album

		// Track changed
		if currentTrack == nil || (currentTrack != nil && track != currentTrack!)
		{
			DispatchQueue.main.async {
				NotificationCenter.default.post(name: .playingTrackChanged, object: nil, userInfo: infos)
			}
		}

		// Status changed
		if currentStatus.rawValue != status
		{
			DispatchQueue.main.async {
				NotificationCenter.default.post(name: .playerStatusChanged, object: nil, userInfo: infos)
			}
		}

		self.currentStatus = PlayerStatus(rawValue: status)!
		currentTrack = track
		currentAlbum = album
		DispatchQueue.main.async {
			NotificationCenter.default.post(name: .currentPlayingTrack, object: nil, userInfo: infos)
		}
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
}

extension PlayerController : AudioServerConnectionDelegate
{
	func albumMatchingName(_ name: String) -> Album?
	{
		let albums = MusicDataSource.shared.albums
		return albums.filter({$0.name == name}).first
	}
}
