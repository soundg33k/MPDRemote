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
		get {return frame.origin.x}
		set {frame.origin.x = newValue}
	}

	var y: CGFloat
	{
		get {return frame.origin.y}
		set {frame.origin.y = newValue}
	}

	var width: CGFloat
	{
		get {return frame.width}
		set {frame.size.width = newValue}
	}

	var height: CGFloat
	{
		get {return frame.height}
		set {frame.size.height = newValue}
	}

	var origin: CGPoint
	{
		get {return frame.origin}
		set {frame.origin = newValue}
	}

	var size: CGSize
	{
		get {return frame.size}
		set {frame.size = newValue}
	}

	// MARK: - Edges
	public var left: CGFloat
	{
		get {return origin.x}
		set {origin.x = newValue}
	}

	public var right: CGFloat
	{
		get {return x + width}
		set {x = newValue - width}
	}

	public var top: CGFloat
	{
		get {return y}
		set {y = newValue}
	}

	public var bottom: CGFloat
	{
		get {return y + height}
		set {y = newValue - height}
	}
}
