// MPDServer.swift
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


enum AudioServerType : Int
{
	case mpd
}


final class AudioServer : NSObject, NSCoding
{
	// MARK: - Properties
	// Server type, only mpd supported
	let type: AudioServerType
	// Server name
	let name: String
	// Server IP / hostname
	let hostname: String
	// Server port
	let port: UInt16
	// Server password
	var password: String = ""

	// MARK: - Initializers
	init(type: AudioServerType, name: String, hostname: String, port: UInt16)
	{
		self.type = type
		self.name = name
		self.hostname = hostname
		self.port = port
	}

	convenience init(type: AudioServerType, name: String, hostname: String, port: UInt16, password: String)
	{
		self.init(type:type, name:name, hostname:hostname, port:port)
		self.password = password
	}

	// MARK: - NSCoding
	required convenience init?(coder decoder: NSCoder)
	{
		guard let type = decoder.decodeObject(forKey: "type") as? Int,
			let name = decoder.decodeObject(forKey: "name") as? String,
			let hostname = decoder.decodeObject(forKey: "hostname") as? String,
			let password = decoder.decodeObject(forKey: "password") as? String,
			let port = decoder.decodeObject(forKey: "port") as? Int
			else { return nil }
		
		self.init(type:AudioServerType(rawValue: type)!, name:name, hostname:hostname, port:UInt16(port), password:password)
	}

	func encode(with coder: NSCoder)
	{
		coder.encode(type.rawValue, forKey:"type")
		coder.encode(name, forKey:"name")
		coder.encode(hostname, forKey:"hostname")
		coder.encode(Int(port), forKey:"port")
		coder.encode(password, forKey:"password")
	}
}
