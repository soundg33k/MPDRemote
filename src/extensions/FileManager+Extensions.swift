// FileManager+Extensions.swift
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


extension FileManager
{
	func sizeOfDirectoryAtURL(_ directoryURL: URL) -> Int
	{
		var result = 0
		let props = [URLResourceKey.localizedNameKey, URLResourceKey.creationDateKey, URLResourceKey.localizedTypeDescriptionKey]

		do
		{
			let ar = try self.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: props, options: [])
			for url in ar
			{
				var isDir: ObjCBool = false
				self.fileExists(atPath: url.path, isDirectory: &isDir)
				if isDir.boolValue
				{
					result += self.sizeOfDirectoryAtURL(url)
				}
				else
				{
					result += try self.attributesOfItem(atPath: url.path)[FileAttributeKey.size] as! Int
				}
			}
		}
		catch _
		{
			Logger.alog("[!] Cant' get directory size")
		}

		return result
	}
}
