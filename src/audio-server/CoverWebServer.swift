// CoverWebServer.swift
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


final class CoverWebServer : Server
{
	// MARK: - Public properties
	// Name of the cover files
	var coverName: String = "cover.jpg"

	// MARK: - Initializers
	init(name: String, hostname: String, port: UInt16, coverName: String)
	{
		super.init(name: name, hostname: hostname, port: port)
		self.coverName = coverName
	}

	init(name: String, hostname: String, port: UInt16, password: String, coverName: String)
	{
		super.init(name: name, hostname: hostname, port: port, password: password)
		self.coverName = coverName
	}

	// MARK: - NSCoding
	required convenience init?(coder decoder: NSCoder)
	{
		guard let name = decoder.decodeObject(forKey: "name") as? String,
			let hostname = decoder.decodeObject(forKey: "hostname") as? String,
			let password = decoder.decodeObject(forKey: "password") as? String,
			let coverName = decoder.decodeObject(forKey: "covername") as? String
			else { return nil }

		let port = decoder.decodeInteger(forKey: "port")

		self.init(name: name, hostname: hostname, port: UInt16(port), password: password, coverName: coverName)
	}

	override func encode(with coder: NSCoder)
	{
		coder.encode(coverName, forKey: "covername")
		super.encode(with: coder)
	}
}
