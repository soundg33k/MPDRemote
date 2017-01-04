// Server.swift
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


class Server : NSObject, NSCoding
{
	// MARK: - Public properties
	// Server name
	var name: String
	// Server IP / hostname
	var hostname: String
	// Server port
	var port: UInt16
	// Server password
	var password: String = ""

	// MARK: - Initializers
	init(name: String, hostname: String, port: UInt16)
	{
		self.name = name
		self.hostname = hostname
		self.port = port
	}

	init(name: String, hostname: String, port: UInt16, password: String)
	{
		self.name = name
		self.hostname = hostname
		self.port = port
		self.password = password
	}

	// MARK: - NSCoding
	required convenience init?(coder decoder: NSCoder)
	{
		guard let name = decoder.decodeObject(forKey: "name") as? String,
			let hostname = decoder.decodeObject(forKey: "hostname") as? String,
			let password = decoder.decodeObject(forKey: "password") as? String
			else { return nil }

		let port = decoder.decodeInteger(forKey: "port")
		self.init(name: name, hostname: hostname, port: UInt16(port), password: password)
	}

	func encode(with coder: NSCoder)
	{
		coder.encode(name, forKey: "name")
		coder.encode(hostname, forKey: "hostname")
		coder.encode(Int(port), forKey: "port")
		coder.encode(password, forKey: "password")
	}
}

// MARK: - Operators
func == (lhs: Server, rhs: Server) -> Bool
{
	return (lhs.name == rhs.name && lhs.hostname == rhs.hostname && lhs.port == rhs.port && lhs.password == rhs.password)
}
