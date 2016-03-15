// CGRect+Extensions.swift
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


import CoreGraphics


extension CGRect
{
	// MARK: - Initializers
	public init(_ origin: CGPoint, _ size: CGSize)
	{
		self.origin = origin
		self.size = size
	}

	public init(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat)
	{
		self.origin = CGPoint(x, y)
		self.size = CGSize(width, height)
	}

	public init(_ x: CGFloat, _ y: CGFloat, _ size: CGSize)
	{
		self.origin = CGPoint(x, y)
		self.size = size
	}

	public init(_ origin: CGPoint, _ width: CGFloat, _ height: CGFloat)
	{
		self.origin = origin
		self.size = CGSize(width, height)
	}

	// MARK: - Shortcuts
	public var x: CGFloat
	{
		get {return self.origin.x}
		set {self.origin.x = newValue}
	}

	public var y: CGFloat
	{
		get {return self.origin.y}
		set {self.origin.y = newValue}
	}

	public var centerX: CGFloat
	{
		get {return self.x + self.width * 0.5}
		set {self.x = newValue - self.width * 0.5}
	}

	public var centerY: CGFloat
	{
		get {return self.y + self.height * 0.5}
		set {self.y = newValue - self.height * 0.5}
	}

	// MARK: - Edges
	public var left: CGFloat
	{
		get {return self.self.origin.x}
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

	// MARK: - Points
	public var topLeft: CGPoint
	{
		get {return CGPoint(x:self.left, y:self.top)}
		set {self.left = newValue.x; self.top = newValue.y}
	}

	public var topCenter: CGPoint
	{
		get {return CGPoint(x:self.centerX, y:self.top)}
		set {self.centerX = newValue.x; self.top = newValue.y}
	}

	public var topRight: CGPoint
	{
		get {return CGPoint(x:self.right, y:self.top)}
		set {self.right = newValue.x; self.top = newValue.y}
	}

	public var centerLeft: CGPoint
	{
		get {return CGPoint(x:self.left, y:self.centerY)}
		set {self.left = newValue.x; self.centerY = newValue.y}
	}

	public var center: CGPoint
	{
		get {return CGPoint(x:self.centerX, y:self.centerY)}
		set {self.centerX = newValue.x; self.centerY = newValue.y}
	}

	public var centerRight: CGPoint
	{
		get {return CGPoint(x:self.right, y:self.centerY)}
		set {self.right = newValue.x; self.centerY = newValue.y}
	}

	public var bottomLeft: CGPoint
	{
		get {return CGPoint(x:self.left, y:self.bottom)}
		set {self.left = newValue.x; self.bottom = newValue.y}
	}

	public var bottomCenter: CGPoint
	{
		get {return CGPoint(x:self.centerX, y:self.bottom)}
		set {self.centerX = newValue.x; self.bottom = newValue.y}
	}

	public var bottomRight: CGPoint
	{
		get {return CGPoint(x:self.right, y:self.bottom)}
		set {self.right = newValue.x; self.bottom = newValue.y}
	}
}
