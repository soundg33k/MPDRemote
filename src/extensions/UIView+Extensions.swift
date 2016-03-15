// UIView+Extensions.swift
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


import UIKit


extension UIView
{
	// MARK: - Shortcuts
	var x: CGFloat
	{
		get {return self.frame.origin.x}
		set {self.frame.origin.x = newValue}
	}

	var y: CGFloat
	{
		get {return self.frame.origin.y}
		set {self.frame.origin.y = newValue}
	}

	var width: CGFloat
	{
		get {return self.frame.width}
		set {self.frame.size.width = newValue}
	}

	var height: CGFloat
	{
		get {return self.frame.height}
		set {self.frame.size.height = newValue}
	}

	var origin: CGPoint
	{
		get {return self.frame.origin}
		set {self.frame.origin = newValue}
	}

	var size: CGSize
	{
		get {return self.frame.size}
		set {self.frame.size = newValue}
	}

	// MARK: - Edges
	public var left: CGFloat
	{
		get {return self.origin.x}
		set {self.origin.x = newValue}
	}

	public var right: CGFloat
	{
		get {return self.x + self.width}
		set {self.x = newValue - self.width}
	}

	public var top: CGFloat
	{
		get {return self.y}
		set {self.y = newValue}
	}

	public var bottom: CGFloat
	{
		get {return self.y + self.height}
		set {self.y = newValue - self.height}
	}
}
