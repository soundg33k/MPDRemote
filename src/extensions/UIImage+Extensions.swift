// UIImage+Extensions.swift
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
import ImageIO


extension UIImage
{
	func imageCroppedToFitSize(fitSize: CGSize) -> UIImage?
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

		let destRect = CGRectIntegral(CGRect(CGPointZero, fitSize))
		// Crop center
		let destX = CGFloat(round((scaledWidth - targetWidth) * 0.5))
		let destY = CGFloat(round((scaledHeight - targetHeight) * 0.5))
		let sourceRect = CGRectIntegral(CGRect(ceil(destX / scaleFactor), destY / scaleFactor, targetWidth / scaleFactor, targetHeight / scaleFactor))

		// Create scale-cropped image
		UIGraphicsBeginImageContextWithOptions(destRect.size, false, 0.0) // 0.0 = scale for device's main screen
		let sourceImg = CGImageCreateWithImageInRect(CGImage, sourceRect) // cropping happens here
		var image = UIImage(CGImage:sourceImg!, scale:0.0, orientation:imageOrientation)
		image.drawInRect(destRect) // the actual scaling happens here, and orientation is taken care of automatically
		image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return image
	}

	func imageScaledToFitSize(fitSize: CGSize) -> UIImage?
	{
		guard let cgImage = CGImage else {return nil}

		let width = ceil(fitSize.width * scale)
		let height = ceil(fitSize.height * scale)

		let context = CGBitmapContextCreate(nil, Int(width), Int(width), CGImageGetBitsPerComponent(cgImage), CGImageGetBytesPerRow(cgImage), CGImageGetColorSpace(cgImage), CGImageGetBitmapInfo(cgImage).rawValue)
		CGContextSetInterpolationQuality(context, .High)
		CGContextDrawImage(context, CGRect(CGPointZero, width, height), cgImage)

		if let scaledImageRef = CGBitmapContextCreateImage(context)
		{
			return UIImage(CGImage:scaledImageRef)
		}

		return nil
	}

	func imageTintedWithColor(color: UIColor, opacity: CGFloat = 0.0) -> UIImage?
	{
		UIGraphicsBeginImageContextWithOptions(size, false, 0.0)

		let rect = CGRect(0.0, 0.0, size.width, size.height)
		color.set()
		UIRectFill(rect)

		drawInRect(rect, blendMode:.DestinationIn, alpha:1.0)

		if (opacity > 0.0)
		{
			drawInRect(rect, blendMode:.SourceAtop, alpha:opacity)
		}
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return image
	}

	class func loadFromURL(URL: NSURL) -> UIImage?
	{
		guard let imageSource = CGImageSourceCreateWithURL(URL, nil) else {return nil}
		guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, [kCGImageSourceShouldCache as String : true]) else {return nil}
		let image = UIImage(CGImage:imageRef)
		return image
	}

	class func fromString(string: String, font: UIFont, fontColor: UIColor, backgroundColor: UIColor, maxSize: CGSize) -> UIImage?
	{
		// Create an attributed string with string and font information
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineBreakMode = .ByWordWrapping
		paragraphStyle.alignment = .Center
		let attributes = [NSFontAttributeName : font, NSForegroundColorAttributeName : fontColor, NSParagraphStyleAttributeName : paragraphStyle]
		let attrString = NSAttributedString(string:string, attributes:attributes)
		let scale = UIScreen.mainScreen().scale
		let trueMaxSize = maxSize * scale

		// Figure out how big an image we need
		let framesetter = CTFramesetterCreateWithAttributedString(attrString)
		var osef = CFRange(location:0, length:0)
		let goodSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, osef, nil, trueMaxSize, &osef).ceil()
		let rect = CGRect((trueMaxSize.width - goodSize.width) * 0.5, (trueMaxSize.height - goodSize.height) * 0.5, goodSize.width, goodSize.height)
		let path = CGPathCreateWithRect(rect, nil)
		let frame = CTFramesetterCreateFrame(framesetter, CFRange(location:0, length:0), path, nil)

		// Create the context and fill it
		guard let bmContext = BitmapContext.ARGBBitmapContext(width:Int(trueMaxSize.width), height:Int(trueMaxSize.height), withAlpha:true) else
		{
			return nil
		}
		CGContextSetFillColorWithColor(bmContext, backgroundColor.CGColor)
		CGContextFillRect(bmContext, /*rect*/CGRect(CGPointZero, trueMaxSize))

		// Draw the text
		CGContextSetAllowsAntialiasing(bmContext, true)
		CGContextSetAllowsFontSmoothing(bmContext, true)
		CGContextSetInterpolationQuality(bmContext, .High)
		CTFrameDraw(frame, bmContext)

		// Save
		if let imageRef = CGBitmapContextCreateImage(bmContext)
		{
			let img = UIImage(CGImage:imageRef)
			return img
		}
		else
		{
			return nil
		}
	}
}
