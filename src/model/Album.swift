// Album.swift
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


final class Album
{
	// MARK: - Properties
	// Album name
	var name: String
	// Album artist
	var artist: String = ""
	// Album genre
	var genre: String = ""
	// Album release date
	var year: String = ""
	// Album path
	var path: String? = nil
	// Album tracks
	var songs: [Track]? = nil
	// Flag to indicate if the album has an associated cover
	var hasCover = true
	// Local URL for the cover
	lazy var localCoverURL: NSURL? = {
		guard let cachesDirectoryURL = NSFileManager().URLsForDirectory(.CachesDirectory, inDomains:.UserDomainMask).last else {return nil}
		guard let coverDirectoryPath = NSUserDefaults.standardUserDefaults().stringForKey(kNYXPrefDirectoryCovers) else {return nil}
		return cachesDirectoryURL.URLByAppendingPathComponent(coverDirectoryPath, isDirectory:true).URLByAppendingPathComponent(self.name.md5() + ".jpg")
	}()

	// MARK: - Initializers
	init(name: String)
	{
		self.name = name
	}

	convenience init(name: String, artist: String)
	{
		self.init(name:name)

		self.artist = artist
	}
}

extension Album : CustomStringConvertible
{
	var description:String
	{
		return "Name: <\(self.name)>\nArtist: <\(self.artist)>\nGenre: <\(self.genre)>\nYear: <\(self.year)>\nPath: <\(self.path)>"
	}
}
