// WEBServer.swift
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


final class WEBServer : NSObject, NSCoding
{
	// MARK: - Properties
	// HTTP url for covers
	let coverURL: String
	// Name of the cover files
	var coverName: String = "cover.jpg"

	// MARK: - Initializers
	init(coverURL: String)
	{
		self.coverURL = coverURL
	}

	convenience init(coverURL: String, coverName: String)
	{
		self.init(coverURL:coverURL)
		self.coverName = coverName
	}

	// MARK: - NSCoding
	required convenience init?(coder decoder: NSCoder)
	{
		guard let coverURL = decoder.decodeObjectForKey("coverurl") as? String,
			let coverName = decoder.decodeObjectForKey("covername") as? String
			else { return nil }

		self.init(coverURL:coverURL, coverName:coverName)
	}

	func encodeWithCoder(coder: NSCoder)
	{
		coder.encodeObject(self.coverURL, forKey:"coverurl")
		coder.encodeObject(self.coverName, forKey:"covername")
	}
}
