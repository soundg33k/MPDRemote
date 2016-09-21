// AudioServerConnection.swift
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


public let kPlayerTrackKey = "track"
public let kPlayerAlbumKey = "album"
public let kPlayerElapsedKey = "elapsed"
public let kPlayerStatusKey = "status"


protocol AudioServerConnectionDelegate : class
{
	func albumMatchingName(_ name: String) -> Album?
}

protocol AudioServerConnection
{
	// MARK: - Properties
	// Delegate
	weak var delegate: AudioServerConnectionDelegate? {get set}
	// Connected flag
	var connected: Bool {get}

	// MARK: - Connection
	func connect() -> Bool
	func disconnect()

	// MARK: - Get infos about tracks / albums / etc…
	func getListForDisplayType(_ displayType: DisplayType) -> [AnyObject]
	func getAlbumForGenre(_ genre: Genre) -> Album?
	func getAlbumsForGenre(_ genre: Genre) -> [Album]
	func getAlbumsForArtist(_ artist: Artist) -> [Album]
	func getArtistsForGenre(_ genre: Genre) -> [Artist]
	func getPathForAlbum(_ album: Album) -> String?
	func getSongsForAlbum(_ album: Album) -> [Track]?
	func getMetadatasForAlbum(_ album: Album) -> [String : Any]

	// MARK: - Play / Queue
	func playAlbum(_ album: Album, random: Bool, loop: Bool)
	func playTracks(_ tracks: [Track], random: Bool, loop: Bool)
	func addAlbumToQueue(_ album: Album)
	func togglePause() -> Bool
	func nextTrack()
	func previousTrack()
	func setRandom(_ random: Bool)
	func setRepeat(_ loop: Bool)
	func setTrackPosition(_ position: Int, trackPosition: UInt32)
	func setVolume(_ volume: UInt32)

	// MARK: - Player status
	func getStatus()
	func getPlayerInfos() -> [String: Any]?

	// MARK: - Stats
	func getStats() -> [String : String]
}
