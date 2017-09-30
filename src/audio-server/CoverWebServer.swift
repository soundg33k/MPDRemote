// CoverWebServer.swift
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


final class CoverWebServer : Codable
{
	// MARK: - Public properties
	// Server name
	var name: String
	// Server IP / hostname
	var hostname: String
	// Server port
	var port: UInt16
	// Name of the cover files
	var coverName: String = "cover.jpg"

	enum CoverServerCodingKeys: String, CodingKey
	{
		case name
		case hostname
		case port
		case coverName
	}

	// MARK: - Initializers
	init(name: String, hostname: String, port: UInt16, coverName: String)
	{
		self.name = name
		self.hostname = CoverWebServer.sanitizeHostname(hostname)
		self.port = port
		self.coverName = coverName
	}

	required convenience init(from decoder: Decoder) throws
	{
		let values = try decoder.container(keyedBy: CoverServerCodingKeys.self)
		let na = try values.decode(String.self, forKey: .name)
		let ho = try values.decode(String.self, forKey: .hostname)
		let po = try values.decode(UInt16.self, forKey: .port)
		let co = try values.decode(String.self, forKey: .coverName)

		self.init(name: na, hostname: ho, port: po, coverName: co)
	}

	public func publicDescription() -> String
	{
		return "\(self.hostname)\n\(self.port)\n\(self.coverName)"
	}

	// MARK: - Private
	private static func sanitizeHostname(_ hostname: String) -> String
	{
		var h: String
		if hostname.hasPrefix("http://") || hostname.hasPrefix("https://")
		{
			h = hostname
		}
		else
		{
			h = "http://" + hostname
		}

		if h.last == "/"
		{
			h.remove(at: h.index(before: h.endIndex))
		}

		return h
	}
}

// MARK: - Operators
func == (lhs: CoverWebServer, rhs: CoverWebServer) -> Bool
{
	return (lhs.name == rhs.name && lhs.hostname == rhs.hostname && lhs.port == rhs.port && lhs.coverName == rhs.coverName)
}
