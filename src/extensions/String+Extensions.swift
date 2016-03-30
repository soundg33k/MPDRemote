// String+Extensions.swift
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


extension String
{
	// MARK: - String length
	var length: Int
	{
		return self.characters.count
	}
	
	var range: NSRange
	{
		return NSRange(location:0, length:self.length)
	}

	// MARK: - Base64 encode
	func base64Encode() -> String
	{
		let utf8str = self.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion:false)!
		return utf8str.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
	}

	// MARK: - Base64 decode
	func base64Decode() -> String
	{
		if let base64data = NSData(base64EncodedString:self, options:.IgnoreUnknownCharacters)
		{
			return NSString(data:base64data, encoding:NSUTF8StringEncoding)! as String
		}
		return ""
	}

	func md5() -> String
	{
		var digest = [UInt8](count:Int(CC_MD5_DIGEST_LENGTH), repeatedValue:0)
		if let data = self.dataUsingEncoding(NSUTF8StringEncoding)
		{
			CC_MD5(data.bytes, CC_LONG(data.length), &digest)
		}

		let ret = NSMutableString()
		for i in 0 ..< Int(CC_MD5_DIGEST_LENGTH)
		{
			ret.appendFormat("%02x", Int(digest[i]))
		}

		return ret.copy() as! String
	}
}

func NYXLocalizedString(key: String) -> String
{
	return NSLocalizedString(key, comment:"")
}
