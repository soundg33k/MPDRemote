// MathUtilities.swift
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


// MARK: - Clamp
public func clamp<T: Comparable>(value: T, lower: T, upper: T) -> T
{
	return max(min(value, upper), lower)
}

// MARK: - Degrees/Radians
public func degreesToRadians(value: Float) -> Float
{
	return value * Float(M_PI) / 180
}

public func radiansToDegrees(value: Float) -> Float
{
	return value * 180 / Float(M_PI)
}

public func degreesToRadians(value: Double) -> Double
{
	return value * M_PI / 180
}

public func radiansToDegrees(value: Double) -> Double
{
	return value * 180 / M_PI
}

public func degreesToRadians(value: CGFloat) -> CGFloat
{
	return value * CGFloat(M_PI) / 180
}

public func radiansToDegrees(value: CGFloat) -> CGFloat
{
	return value * 180 / CGFloat(M_PI)
}
