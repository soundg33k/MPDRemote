// BitmapContext.swift
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


// MARK: - Private
private var _rgbToken: dispatch_once_t = 0
private var _grayToken: dispatch_once_t = 0
private var _rgbColorSpace: CGColorSpaceRef? = nil
private var _grayColorSpace: CGColorSpaceRef? = nil

// MARK: - Public constants
public let kNYXNumberOfComponentsPerARBGPixel = 4
public let kNYXNumberOfComponentsPerRGBAPixel = 4
public let kNYXNumberOfComponentsPerGrayPixel = 3
public let kNYXMinPixelComponentValue = UInt8(0)
public let kNYXMaxPixelComponentValue = UInt8(255)


final class BitmapContext
{
	// MARK: - RGB colorspace
	class func RGBColorSpace() -> CGColorSpaceRef?
	{
		dispatch_once(&_rgbToken)
		{
			_rgbColorSpace = CGColorSpaceCreateDeviceRGB()
		}
		return _rgbColorSpace
	}

	// MARK: - Gray colorspace
	class func GrayColorSpace() -> CGColorSpaceRef?
	{
		dispatch_once(&_grayToken)
		{
			_grayColorSpace = CGColorSpaceCreateDeviceGray()
		}
		return _grayColorSpace
	}

	// MARK: - ARGB bitmap context
	class func ARGBBitmapContext(width width: Int, height: Int, withAlpha: Bool) -> CGContextRef?
	{
		let alphaInfo = CGBitmapInfo(rawValue: withAlpha ? CGImageAlphaInfo.PremultipliedFirst.rawValue : CGImageAlphaInfo.NoneSkipFirst.rawValue)
		let bmContext = CGBitmapContextCreate(nil, width, height, 8/*Bits per component*/, width * kNYXNumberOfComponentsPerARBGPixel/*Bytes per row*/, BitmapContext.RGBColorSpace(), alphaInfo.rawValue)
		return bmContext
	}

	// MARK: - RGBA bitmap context
	class func RGBABitmapContext(width width: Int, height: Int, withAlpha: Bool) -> CGContextRef?
	{
		let alphaInfo = CGBitmapInfo(rawValue: withAlpha ? CGImageAlphaInfo.PremultipliedLast.rawValue : CGImageAlphaInfo.NoneSkipLast.rawValue)
		let bmContext = CGBitmapContextCreate(nil, width, height, 8/*Bits per component*/, width * kNYXNumberOfComponentsPerRGBAPixel/*Bytes per row*/, BitmapContext.RGBColorSpace(), alphaInfo.rawValue)
		return bmContext
	}

	// MARK: - Gray bitmap context
	class func GrayBitmapContext(width width: Int, height: Int) -> CGContextRef?
	{
		let bmContext = CGBitmapContextCreate(nil, width, height, 8/*Bits per component*/, width * kNYXNumberOfComponentsPerGrayPixel/*Bytes per row*/, BitmapContext.GrayColorSpace(), CGImageAlphaInfo.None.rawValue)
		return bmContext
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

// MARK: - Operators
func == (lhs: RGBAPixel, rhs: RGBAPixel) -> Bool
{
	return (lhs.r == rhs.r) && (lhs.g == rhs.g) && (lhs.b == rhs.b) && (lhs.a == rhs.a)
}
