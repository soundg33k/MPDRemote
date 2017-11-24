// CGContext+Extensions.swift
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


import UIKit
import CoreGraphics


// MARK: - Public constants
public let kNYXNumberOfComponentsPerARBGPixel = 4
public let kNYXNumberOfComponentsPerRGBAPixel = 4


extension CGContext
{
	// MARK: - ARGB bitmap context
	class func ARGBBitmapContext(width: Int, height: Int, withAlpha: Bool, wideGamut: Bool) -> CGContext?
	{
		let alphaInfo = withAlpha ? CGImageAlphaInfo.premultipliedFirst : CGImageAlphaInfo.noneSkipFirst
		let bmContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * kNYXNumberOfComponentsPerARBGPixel, space: wideGamut ? CGColorSpace.NYXAppropriateColorSpace() : CGColorSpaceCreateDeviceRGB(), bitmapInfo: alphaInfo.rawValue)
		return bmContext
	}

	// MARK: - RGBA bitmap context
	class func RGBABitmapContext(width: Int, height: Int, withAlpha: Bool, wideGamut: Bool) -> CGContext?
	{
		let alphaInfo = withAlpha ? CGImageAlphaInfo.premultipliedLast : CGImageAlphaInfo.noneSkipLast
		let bmContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * kNYXNumberOfComponentsPerRGBAPixel, space: wideGamut ? CGColorSpace.NYXAppropriateColorSpace() : CGColorSpaceCreateDeviceRGB(), bitmapInfo: alphaInfo.rawValue)
		return bmContext
	}
}

extension CGColorSpace
{
	class func NYXAppropriateColorSpace() -> CGColorSpace
	{
		if UIScreen.main.traitCollection.displayGamut == .P3
		{
			if let p3ColorSpace = CGColorSpace(name: CGColorSpace.displayP3)
			{
				return p3ColorSpace
			}
		}
		return CGColorSpaceCreateDeviceRGB()
	}
}

struct RGBAPixel
{
	var r: UInt8
	var g: UInt8
	var b: UInt8
	var a: UInt8

	init(r: UInt8, g: UInt8, b: UInt8, a: UInt8)
	{
		self.r = r
		self.g = g
		self.b = b
		self.a = a
	}
}
