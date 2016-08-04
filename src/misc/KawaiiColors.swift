// KawaiiColors.swift
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

// Converted and adapted to Swift from : https://github.com/fleitz/ColorArt


import UIKit


private let __threshold = UInt(2)
private let __defaultPrecision = Int(8) // 8 -> 256


enum SamplingEdge
{
	case Left
	case Right
}


final class KawaiiColors
{
	// MARK: - Properties
	// Image to analyze
	let image: UIImage
	// Edge color precision
	private(set) var precision = __defaultPrecision
	// Sampling edge for background color
	private(set) var samplingEdge = SamplingEdge.Right
	// Most dominant color in the whole image
	private(set) var dominantColor: UIColor! = nil
	// Most dominant edge color
	private(set) var edgeColor: UIColor! = nil
	// First contrasting color
	private(set) var primaryColor: UIColor! = nil
	// Second contrasting color
	private(set) var secondaryColor: UIColor! = nil
	// Third contrasting color
	private(set) var thirdColor: UIColor! = nil

	// MARK: - Initializers
	init(image: UIImage)
	{
		self.image = image
	}

	convenience init(image: UIImage, precision: Int)
	{
		self.init(image:image)
		self.precision = clamp(precision, lower:8, upper:256)
	}

	convenience init(image: UIImage, samplingEdge: SamplingEdge)
	{
		self.init(image:image)
		self.samplingEdge = samplingEdge
	}

	convenience init(image: UIImage, precision: Int, samplingEdge: SamplingEdge)
	{
		self.init(image:image, precision:precision)
		self.samplingEdge = samplingEdge
	}

	// MARK: - Public
	func analyze()
	{
		// Find edge color
		var imageColors = [CountedObject<UIColor>]()
		edgeColor = _findEdgeColor(&imageColors)
		if edgeColor == nil
		{
			edgeColor = UIColor.whiteColor()
		}

		// Find other colors
		_findContrastingColors(imageColors)

		// Sanitize
		let darkBackground = edgeColor.isDarkColor()
		if primaryColor == nil
		{
			primaryColor = darkBackground ? UIColor.whiteColor() : UIColor.blackColor()
		}

		if secondaryColor == nil
		{
			secondaryColor = darkBackground ? UIColor.whiteColor() : UIColor.blackColor()
		}

		if thirdColor == nil
		{
			thirdColor = darkBackground ? UIColor.whiteColor() : UIColor.blackColor()
		}
	}

	// MARK: - Private
	private func _findEdgeColor(inout colors: [CountedObject<UIColor>]) -> UIColor?
	{
		// Get raw image pixels
		let cgImage = image.CGImage
		let width = CGImageGetWidth(cgImage)
		let height = CGImageGetHeight(cgImage)

		let bmContext = BitmapContext.RGBABitmapContext(width:width, height:height, withAlpha:false)
		CGContextDrawImage(bmContext, CGRect(0.0, 0.0, CGFloat(width), CGFloat(height)), cgImage)
		let data = CGBitmapContextGetData(bmContext)
		if data == nil
		{
			return nil
		}
		let pixels = UnsafeMutablePointer<RGBAPixel>(data)

		let pp = precision
		let scale = UInt8(256 / pp)
		var rawImageColors: [[[UInt]]] = [[[UInt]]](count:pp, repeatedValue:[[UInt]](count:pp, repeatedValue:[UInt](count:pp, repeatedValue:0)))
		var rawEdgeColors: [[[UInt]]] = [[[UInt]]](count:pp, repeatedValue:[[UInt]](count:pp, repeatedValue:[UInt](count:pp, repeatedValue:0)))

		let edge = samplingEdge == .Left ? 0 : width - 1
		for y in 0 ..< height
		{
			for x in 0 ..< width
			{
				let index = x + y * width
				let pixel = pixels[index]
				let r = pixel.r / scale
				let g = pixel.g / scale
				let b = pixel.b / scale
				rawImageColors[Int(r)][Int(g)][Int(b)] += 1
				if x == edge
				{
					rawEdgeColors[Int(r)][Int(g)][Int(b)] += 1
				}
			}
		}

		var edgeColors = [CountedObject<UIColor>]()

		let ppf = CGFloat(pp)
		for b in 0 ..< pp
		{
			for g in 0 ..< pp
			{
				for r in 0 ..< pp
				{
					var count = rawImageColors[r][g][b]
					if count > __threshold
					{
						let color = UIColor(red:CGFloat(r) / ppf, green:CGFloat(g) / ppf, blue:CGFloat(b) / ppf, alpha:1.0)
						colors.append(CountedObject(object:color, count:count))
					}

					count = rawEdgeColors[r][g][b]
					if count > __threshold
					{
						let color = UIColor(red:CGFloat(r) / ppf, green:CGFloat(g) / ppf, blue:CGFloat(b) / ppf, alpha:1.0)
						edgeColors.append(CountedObject(object:color, count:count))
					}
				}
			}
		}
		colors.sortInPlace { (c1: CountedObject<UIColor>, c2: CountedObject<UIColor>) -> Bool in
			return c1.count > c2.count
		}
		dominantColor = colors.count > 0 ? colors[0].object : UIColor.blackColor()

		if edgeColors.count > 0
		{
			edgeColors.sortInPlace { (c1: CountedObject<UIColor>, c2: CountedObject<UIColor>) -> Bool in
				return c1.count > c2.count
			}

			var proposedEdgeColor = edgeColors[0]
			if proposedEdgeColor.object.isBlackOrWhite() // want to choose color over black/white so we keep looking
			{
				for i in 1 ..< edgeColors.count
				{
					let nextProposedColor = edgeColors[i]

					// make sure the second choice color is 40% as common as the first choice
					if (Double(nextProposedColor.count) / Double(proposedEdgeColor.count)) > 0.4
					{
						if !nextProposedColor.object.isBlackOrWhite()
						{
							proposedEdgeColor = nextProposedColor
							break
						}
					}
					else
					{
						// reached color threshold less than 40% of the original proposed edge color so bail
						break
					}
				}
			}
			return proposedEdgeColor.object
		}
		else
		{
			return nil
		}
	}

	private func _findContrastingColors(colors: [CountedObject<UIColor>])
	{
		var sortedColors = [CountedObject<UIColor>]()
		let findDarkTextColor = !edgeColor.isDarkColor()

		for countedColor in colors
		{
			let cc = countedColor.object.colorWithMinimumSaturation(0.15)

			if cc.isDarkColor() == findDarkTextColor
			{
				let colorCount = countedColor.count
				sortedColors.append(CountedObject(object:cc, count:colorCount))
			}
		}

		sortedColors.sortInPlace { (c1: CountedObject<UIColor>, c2: CountedObject<UIColor>) -> Bool in
			return c1.count > c2.count
		}

		for curContainer in sortedColors
		{
			let curColor = curContainer.object

			if primaryColor == nil
			{
				if curColor.isContrastingColor(edgeColor)
				{
					primaryColor = curColor
				}
			}
			else if secondaryColor == nil
			{
				if !primaryColor.isDistinct(curColor) || !curColor.isContrastingColor(edgeColor)
				{
					continue
				}
				secondaryColor = curColor
			}
			else if thirdColor == nil
			{
				if !secondaryColor.isDistinct(curColor) || !primaryColor.isDistinct(curColor) || !curColor.isContrastingColor(edgeColor)
				{
					continue
				}

				thirdColor = curColor
				break
			}
		}
	}
}
