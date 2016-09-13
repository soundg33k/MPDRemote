// String+Extensions.swift
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


extension String
{
	// MARK: - String length
	var length: Int
	{
		return characters.count
	}

	var range: NSRange
	{
		return NSRange(location:0, length:length)
	}

	// MARK: - Base64 encode
	func base64Encode() -> String
	{
		if let utf8str = data(using: String.Encoding.utf8)
		{
			return utf8str.base64EncodedString(options: .lineLength64Characters)
		}
		return ""
	}

	// MARK: - Base64 decode
	func base64Decode() -> String
	{
		if let base64data = Data(base64Encoded:self, options:[])
		{
			if let str = String(data:base64data, encoding:String.Encoding.utf8)
			{
				return str
			}
		}
		return ""
	}

	// MARK: - Hash functions
	func md5() -> String
	{
		var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
		if let data = data(using: String.Encoding.utf8)
		{
			CC_MD5((data as NSData).bytes, CC_LONG(data.count), &digest)
		}

		var ret = ""
		for i in 0 ..< Int(CC_MD5_DIGEST_LENGTH)
		{
			ret += String(format:"%02x", digest[i])
		}
		return ret
	}

	func djb2() -> Int
	{
		return utf8.reduce(5381){($0 << 5) &+ $0 &+ Int($1)}
	}
}

func NYXLocalizedString(_ key: String) -> String
{
	return NSLocalizedString(key, comment:"")
}
