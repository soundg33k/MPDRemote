// UIImage+Extensions.swift
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
import ImageIO


extension UIImage
{
	func imageCroppedToFitSize(_ fitSize: CGSize) -> UIImage?
	{
		let sourceWidth = size.width * scale
		let sourceHeight = size.height * scale
		let targetWidth = fitSize.width
		let targetHeight = fitSize.height

		// Calculate aspect ratios
		let sourceRatio = sourceWidth / sourceHeight
		let targetRatio = targetWidth / targetHeight

		// Determine what side of the source image to use for proportional scaling
		let scaleWidth = (sourceRatio <= targetRatio)

		// Proportionally scale source image
		var scalingFactor: CGFloat, scaledWidth: CGFloat, scaledHeight: CGFloat
		if (scaleWidth)
		{
			scalingFactor = 1.0 / sourceRatio
			scaledWidth = targetWidth
			scaledHeight = CGFloat(round(targetWidth * scalingFactor))
		}
		else
		{
			scalingFactor = sourceRatio
			scaledWidth = CGFloat(round(targetHeight * scalingFactor))
			scaledHeight = targetHeight
		}
		let scaleFactor = scaledHeight / sourceHeight

		let destRect = CGRect(CGPoint.zero, fitSize).integral
		// Crop center
		let destX = CGFloat(round((scaledWidth - targetWidth) * 0.5))
		let destY = CGFloat(round((scaledHeight - targetHeight) * 0.5))
		let sourceRect = CGRect(ceil(destX / scaleFactor), destY / scaleFactor, targetWidth / scaleFactor, targetHeight / scaleFactor).integral

		// Create scale-cropped image
		let renderer = UIGraphicsImageRenderer(size: destRect.size)
		return renderer.image() { rendererContext in
			let sourceImg = cgImage?.cropping(to: sourceRect) // cropping happens here
			let image = UIImage(cgImage:sourceImg!, scale:0.0, orientation:imageOrientation)
			image.draw(in: destRect) // the actual scaling happens here, and orientation is taken care of automatically
		}
	}

	func imageScaledToFitSize(_ fitSize: CGSize) -> UIImage?
	{
		guard let cgImage = cgImage else {return nil}

		let width = ceil(fitSize.width * scale)
		let height = ceil(fitSize.height * scale)

		let context = CGContext(data: nil, width: Int(width), height: Int(width), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: cgImage.bytesPerRow, space: cgImage.colorSpace!, bitmapInfo: cgImage.bitmapInfo.rawValue)
		context!.interpolationQuality = .high
		context?.draw(cgImage, in: CGRect(CGPoint.zero, width, height))

		if let scaledImageRef = context?.makeImage()
		{
			return UIImage(cgImage:scaledImageRef)
		}

		return nil
	}

	func imageTintedWithColor(_ color: UIColor, opacity: CGFloat = 0.0) -> UIImage?
	{
		let renderer = UIGraphicsImageRenderer(size: size)
		return renderer.image() { rendererContext in
			let rect = CGRect(CGPoint.zero, self.size)
			color.set()
			UIRectFill(rect)

			draw(in: rect, blendMode:.destinationIn, alpha:1.0)

			if (opacity > 0.0)
			{
				draw(in: rect, blendMode:.sourceAtop, alpha:opacity)
			}
		}
	}

	class func loadFromFileURL(_ url: URL) -> UIImage?
	{
		guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {return nil}
		let props = [kCGImageSourceShouldCache as String : true]
		guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, props as CFDictionary?) else {return nil}
		let image = UIImage(cgImage:imageRef)
		return image
	}

	class func fromString(_ string: String, font: UIFont, fontColor: UIColor, backgroundColor: UIColor, maxSize: CGSize) -> UIImage?
	{
		// Create an attributed string with string and font information
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineBreakMode = .byWordWrapping
		paragraphStyle.alignment = .center
		let attributes = [NSFontAttributeName : font, NSForegroundColorAttributeName : fontColor, NSParagraphStyleAttributeName : paragraphStyle]
		let attrString = NSAttributedString(string:string, attributes:attributes)
		let scale = UIScreen.main.scale
		let trueMaxSize = maxSize * scale

		// Figure out how big an image we need
		let framesetter = CTFramesetterCreateWithAttributedString(attrString)
		var osef = CFRange(location:0, length:0)
		let goodSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, osef, nil, trueMaxSize, &osef).ceil()
		let rect = CGRect((trueMaxSize.width - goodSize.width) * 0.5, (trueMaxSize.height - goodSize.height) * 0.5, goodSize.width, goodSize.height)
		let path = CGPath(rect: rect, transform: nil)
		let frame = CTFramesetterCreateFrame(framesetter, CFRange(location:0, length:0), path, nil)

		// Create the context and fill it
		guard let bmContext = BitmapContext.ARGBBitmapContext(width:Int(trueMaxSize.width), height:Int(trueMaxSize.height), withAlpha:true) else
		{
			return nil
		}
		bmContext.setFillColor(backgroundColor.cgColor)
		bmContext.fill(CGRect(CGPoint.zero, trueMaxSize))

		// Draw the text
		bmContext.setAllowsAntialiasing(true)
		bmContext.setAllowsFontSmoothing(true)
		bmContext.interpolationQuality = .high
		CTFrameDraw(frame, bmContext)

		// Save
		if let imageRef = bmContext.makeImage()
		{
			let img = UIImage(cgImage:imageRef)
			return img
		}
		else
		{
			return nil
		}
	}
}
