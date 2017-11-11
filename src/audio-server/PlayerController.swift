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
	// Audio outputs list
	private(set) var outputs = [AudioOutput]()
	// List of the tracks of the current queue
	private(set) var listTracksInQueue = [Track]()

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
		self._queue = DispatchQueue(label: "fr.whine.mpdremote.queue.player", qos: .default, attributes: [], autoreleaseFrequency: .inherit, target: nil)

		NotificationCenter.default.addObserver(self, selector: #selector(audioServerConfigurationDidChange(_:)), name: .audioServerConfigurationDidChange, object:nil)
		NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: .UIApplicationDidEnterBackground, object:nil)
		NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object:nil)
	}

	// MARK: - Public
	@discardableResult func initialize() -> Bool
	{
		// Sanity check 1
		if _connection != nil && _connection.isConnected
		{
			return true
		}

		// Sanity check 2
		guard let server = server else
		{
			MessageView.shared.showWithMessage(message: Message(content: NYXLocalizedString("lbl_message_no_mpd_server"), type: .error))
			return false
		}

		// Connect
		_connection = MPDConnection(server)
		let ret = _connection.connect()
		if ret.succeeded
		{
			_connection.delegate = self
			startTimer(500)
		}
		else
		{
			MessageView.shared.showWithMessage(message: ret.messages.first!)
			_connection = nil
		}
		return ret.succeeded
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

	@discardableResult func reinitialize() -> Bool
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
			_ = self._connection.playAlbum(album, shuffle: shuffle, loop: loop)
		}
	}

	func playTracks(_ tracks: [Track], shuffle: Bool, loop: Bool)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			_ = self._connection.playTracks(tracks, shuffle: shuffle, loop: loop)
		}
	}

	func playPlaylist(_ playlist: Playlist, shuffle: Bool, loop: Bool, position: UInt32 = 0)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			_ = self._connection.playPlaylist(playlist, shuffle: shuffle, loop: loop, position: position)
		}
	}

	func playTrackAtPosition(_ position: UInt32)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			_ = self._connection.playTrackAtPosition(position)
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
			_ = self._connection.addAlbumToQueue(album)
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
			_ = self._connection.setRepeat(loop)
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
			_ = self._connection.setRandom(random)
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
			_ = self._connection.nextTrack()
		}
	}

	@objc func requestPreviousTrack()
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			_ = self._connection.previousTrack()
		}
	}

	func getSongsOfCurrentQueue(callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			let result = self._connection.getSongsOfCurrentQueue()
			if result.succeeded == false
			{

			}
			else
			{
				self.listTracksInQueue = result.entity!
				callback()
			}
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
			_ = self._connection.setTrackPosition(position, trackPosition: trackPosition)
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
			_ = self._connection.setVolume(UInt32(volume))
		}
	}

	func getVolume(callback: @escaping (Int) -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			let result = self._connection.getVolume()
			if result.succeeded == false
			{

			}
			else
			{
				callback(result.entity!)
			}
		}
	}

	// MARK: - Outputs
	func getAvailableOutputs(callback: @escaping () -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			let result = self._connection.getAvailableOutputs()
			if result.succeeded == false
			{

			}
			else
			{
				self.outputs = result.entity!
				callback()
			}
		}
	}

	func toggleOutput(output: AudioOutput, callback: @escaping (Bool) -> Void)
	{
		if _connection == nil || _connection.isConnected == false
		{
			return
		}

		_queue.async {
			let ret = self._connection.toggleOutput(output: output)
			callback(ret.succeeded)
		}
	}

	// MARK: - Private
	private func startTimer(_ interval: Int)
	{
		_timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: _queue)
		_timer.schedule(deadline: .now(), repeating: .milliseconds(interval))
		_timer.setEventHandler {
			self.playerInformations()
		}
		_timer.resume()
	}

	private func stopTimer()
	{
		if _timer != nil
		{
			_timer.cancel()
			_timer = nil
		}
	}

	private func playerInformations()
	{
		let result = _connection.getPlayerInfos()
		if result.succeeded == false
		{
			return
		}
		guard let infos = result.entity else {return}
		let status = infos[kPlayerStatusKey] as! Int
		let track = infos[kPlayerTrackKey] as! Track
		let album = infos[kPlayerAlbumKey] as! Album

		// Track changed
		if currentTrack == nil || (currentTrack != nil && track != currentTrack!)
		{
			NotificationCenter.default.postOnMainThreadAsync(name: .playingTrackChanged, object: nil, userInfo: infos)
		}

		// Status changed
		if currentStatus.rawValue != status
		{
			NotificationCenter.default.postOnMainThreadAsync(name: .playerStatusChanged, object: nil, userInfo: infos)
		}

		self.currentStatus = PlayerStatus(rawValue: status)!
		currentTrack = track
		currentAlbum = album
		NotificationCenter.default.postOnMainThreadAsync(name: .currentPlayingTrack, object: nil, userInfo: infos)
	}

	// MARK: - Notifications
	@objc func audioServerConfigurationDidChange(_ aNotification: Notification)
	{
		if let server = aNotification.object as? AudioServer
		{
			self.server = server
			self.reinitialize()
		}
	}

	@objc func applicationDidEnterBackground(_ aNotification: Notification)
	{
		deinitialize()
	}

	@objc func applicationWillEnterForeground(_ aNotification: Notification)
	{
		reinitialize()
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
