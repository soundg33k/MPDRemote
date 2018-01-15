// String+Extensions.swift
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


extension String
{
	// MARK: Removal of characters
	func removing(charactersOf string: String) -> String
	{
		let characterSet = CharacterSet(charactersIn: string)
		let components = self.components(separatedBy: characterSet)
		return components.joined(separator: "")
	}

	// MARK: - NULL check
	static func isNullOrEmpty(_ value: String?) -> Bool
	{
		return value == nil || (value?.isEmpty)!
	}

	static func isNullOrWhiteSpace(_ value: String?) -> Bool
	{
		return isNullOrEmpty(value) || value?.trimmingCharacters(in: .whitespacesAndNewlines).count == 0
	}

	func isEmptyOrWhiteSpace() -> Bool
	{
		return self.isEmpty || self.trimmingCharacters(in: .whitespacesAndNewlines).count == 0
	}

	// MARK: Indexes
	subscript (i: Int) -> Character
	{
		return self[index(startIndex, offsetBy: i)]
	}

	subscript (i: Int) -> String
	{
		return String(self[i] as Character)
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
			ret += String(format: "%02x", digest[i])
		}
		return ret
	}

	func sha256() -> String
	{
		var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
		if let data = data(using: String.Encoding.utf8)
		{
			CC_SHA256((data as NSData).bytes, CC_LONG(data.count), &digest)
		}

		var ret = ""
		for i in 0 ..< Int(CC_SHA256_DIGEST_LENGTH)
		{
			ret += String(format: "%02x", digest[i])
		}
		return ret
	}

	func djb2() -> Int32
	{
		return utf8.reduce(5381){($0 << 5) &+ $0 &+ Int32($1)}
	}

	func fuzzySearch(withString searchString: String, diacriticSensitive: Bool = false, caseSensitive: Bool = false) -> Bool
	{
		if searchString.count == 0 || self.count == 0
		{
			return false
		}

		if searchString.count > self.count
		{
			return false
		}

		var sourceString = self
		var searchWithWildcards = "*\(searchString)*"
		if searchWithWildcards.count > 3
		{
			for i in stride(from: 2, through: searchString.count * 2, by: 2)
			{
				searchWithWildcards.insert("*", at: searchWithWildcards.index(searchWithWildcards.startIndex, offsetBy: i))
			}
		}

		// Not case sensitive
		if caseSensitive == false
		{
			sourceString = sourceString.lowercased()
			searchWithWildcards = searchWithWildcards.lowercased()
		}

		let predicate = diacriticSensitive ? NSPredicate(format: "SELF LIKE %@", searchWithWildcards) : NSPredicate(format: "SELF LIKE[d] %@", searchWithWildcards)
		return predicate.evaluate(with: sourceString)
	}
}

func NYXLocalizedString(_ key: String) -> String
{
	return NSLocalizedString(key, comment: "")
}
