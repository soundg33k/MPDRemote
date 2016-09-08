// BitmapContext.swift
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


import UIKit


// MARK: - Private
private var _rgbToken: Int = 0
private var _grayToken: Int = 0
private var _rgbColorSpace: CGColorSpace? = nil
private var _grayColorSpace: CGColorSpace? = nil

// MARK: - Public constants
public let kNYXNumberOfComponentsPerARBGPixel = 4
public let kNYXNumberOfComponentsPerRGBAPixel = 4
public let kNYXNumberOfComponentsPerGrayPixel = 3
public let kNYXMinPixelComponentValue = UInt8(0)
public let kNYXMaxPixelComponentValue = UInt8(255)


final class BitmapContext
{
	private static var __once1: () = {
			_grayColorSpace = CGColorSpaceCreateDeviceGray()
		}()
	private static var __once: () = {
			_rgbColorSpace = CGColorSpaceCreateDeviceRGB()
		}()
	// MARK: - RGB colorspace
	class func RGBColorSpace() -> CGColorSpace?
	{
		_ = BitmapContext.__once
		return _rgbColorSpace
	}

	// MARK: - Gray colorspace
	class func GrayColorSpace() -> CGColorSpace?
	{
		_ = BitmapContext.__once1
		return _grayColorSpace
	}

	// MARK: - ARGB bitmap context
	class func ARGBBitmapContext(width: Int, height: Int, withAlpha: Bool) -> CGContext?
	{
		let alphaInfo = CGBitmapInfo(rawValue: withAlpha ? CGImageAlphaInfo.premultipliedFirst.rawValue : CGImageAlphaInfo.noneSkipFirst.rawValue)
		let bmContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8/*Bits per component*/, bytesPerRow: width * kNYXNumberOfComponentsPerARBGPixel/*Bytes per row*/, space: BitmapContext.RGBColorSpace()!, bitmapInfo: alphaInfo.rawValue)
		return bmContext
	}

	// MARK: - RGBA bitmap context
	class func RGBABitmapContext(width: Int, height: Int, withAlpha: Bool) -> CGContext?
	{
		let alphaInfo = CGBitmapInfo(rawValue: withAlpha ? CGImageAlphaInfo.premultipliedLast.rawValue : CGImageAlphaInfo.noneSkipLast.rawValue)
		let bmContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8/*Bits per component*/, bytesPerRow: width * kNYXNumberOfComponentsPerRGBAPixel/*Bytes per row*/, space: BitmapContext.RGBColorSpace()!, bitmapInfo: alphaInfo.rawValue)
		return bmContext
	}

	// MARK: - Gray bitmap context
	class func GrayBitmapContext(width: Int, height: Int) -> CGContext?
	{
		let bmContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8/*Bits per component*/, bytesPerRow: width * kNYXNumberOfComponentsPerGrayPixel/*Bytes per row*/, space: BitmapContext.GrayColorSpace()!, bitmapInfo: CGImageAlphaInfo.none.rawValue)
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
