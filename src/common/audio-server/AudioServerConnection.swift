// AudioServerConnection.swift
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


public let kPlayerTrackKey = "track"
public let kPlayerAlbumKey = "album"
public let kPlayerElapsedKey = "elapsed"
public let kPlayerStatusKey = "status"
public let kPlayerVolumeKey = "volume"


public enum PlayerStatus : Int
{
	case playing = 0
	case paused = 1
	case stopped = 2
	case unknown = -1
}

public struct AudioOutput
{
	let id: Int
	let name: String
	let enabled: Bool
}


protocol AudioServerConnectionDelegate : class
{
	func albumMatchingName(_ name: String) -> Album?
}

protocol AudioServerConnection
{
	// MARK: - Public properties
	// Delegate
	weak var delegate: AudioServerConnectionDelegate? {get set}
	// Connected flag
	var isConnected: Bool {get}

	// MARK: - Connection
	func connect() -> ActionResult<Void>
	func disconnect()

	// MARK: - Get infos about tracks / albums / etc…
	func getListForDisplayType(_ displayType: DisplayType) -> ActionResult<[MusicalEntity]>
	func getAlbumsForGenre(_ genre: Genre, firstOnly: Bool) -> ActionResult<[Album]>
	func getAlbumsForArtist(_ artist: Artist) -> ActionResult<[Album]>
	func getArtistsForGenre(_ genre: Genre) -> ActionResult<[Artist]>
	func getPathForAlbum(_ album: Album) -> ActionResult<String>
	func getTracksForAlbum(_ album: Album) -> ActionResult<[Track]>
	func getTracksForPlaylist(_ playlist: Playlist) -> ActionResult<[Track]>
	func getMetadatasForAlbum(_ album: Album) -> ActionResult<[String : Any]>

	// MARK: - Playlists
	func getPlaylists() -> ActionResult<[MusicalEntity]>
	func getSongsOfCurrentQueue() -> ActionResult<[Track]>

	// MARK: - Play / Queue
	func playAlbum(_ album: Album, shuffle: Bool, loop: Bool) -> ActionResult<Void>
	func playTracks(_ tracks: [Track], shuffle: Bool, loop: Bool) -> ActionResult<Void>
	func playPlaylist(_ playlist: Playlist, shuffle: Bool, loop: Bool, position: UInt32) -> ActionResult<Void>
	func playTrackAtPosition(_ position: UInt32) -> ActionResult<Void>
	func addAlbumToQueue(_ album: Album) -> ActionResult<Void>
	func togglePause() -> ActionResult<Void>
	func nextTrack() -> ActionResult<Void>
	func previousTrack() -> ActionResult<Void>
	func setRandom(_ random: Bool) -> ActionResult<Void>
	func setRepeat(_ loop: Bool) -> ActionResult<Void>
	func setTrackPosition(_ position: Int, trackPosition: UInt32) -> ActionResult<Void>
	func setVolume(_ volume: UInt32) -> ActionResult<Void>
	func getVolume() -> ActionResult<Int>

	// MARK: - Player status
	func getStatus() -> ActionResult<OpaquePointer>
	func getPlayerInfos() -> ActionResult<[String : Any]>

	// MARK: - Stats
	func getStats() -> ActionResult<[String : String]>
	func updateDatabase() -> ActionResult<Void>

	// MARK: - Outputs
	func getAvailableOutputs() -> ActionResult<[AudioOutput]>
	func toggleOutput(output: AudioOutput) -> ActionResult<Void>
}
