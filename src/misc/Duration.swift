// Duration.swift
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


struct Duration
{
	// MARK: - Properties
	// Value in secondss
	let seconds: UInt

	// MARK: - Initializer
	init(seconds: UInt)
	{
		self.seconds = seconds
	}

	// MARK: - Public
	func minutesRepresentation() -> (minutes: UInt, seconds: UInt)
	{
		return (self.seconds / 60, self.seconds % 60)
	}

	func minutesRepresentationAsString(delim: String = ":") -> String
	{
		let tmp = self.minutesRepresentation()
		return "\(tmp.minutes)\(delim)\(tmp.seconds < 10 ? "0" : "")\(tmp.seconds)"
	}
}

// MARK: - Comparisons
extension Duration : Equatable {}
func ==(lhs: Duration, rhs: Duration) -> Bool
{
	return lhs.seconds == rhs.seconds
}

extension Duration : Comparable {}
func <(lhs: Duration, rhs: Duration) -> Bool
{
	return lhs.seconds < rhs.seconds
}

extension Duration : Hashable
{
	var hashValue: Int
	{
		return self.seconds.hashValue
	}
}

extension Duration : CustomStringConvertible
{
	var description: String
	{
		return String(self.seconds)
	}
}
