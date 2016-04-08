// AlbumCollectionViewCell.swift
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


final class AlbumCollectionViewCell : UICollectionViewCell
{
	// MARK: - Properties
	// Album cover
	private(set) var imageView: UIImageView! = nil
	// Album name
	private(set) var label: UILabel! = nil
	// Original image set
	var image: UIImage? {
		didSet {
			self.imageView.image = self.image
		}
	}
	// Flag to indicate that the cell is being long pressed
	var longPressed: Bool = false {
		didSet {
			if self.longPressed
			{
				self.imageView.layer.borderWidth = 0.5
				if let img = self.image
				{
					guard let ciimg = CIImage(image:img) else {return}
					guard let filter = CIFilter(name:"CIUnsharpMask") else {return}
					filter.setDefaults()
					filter.setValue(ciimg, forKey:kCIInputImageKey)
					guard let result = filter.valueForKey(kCIOutputImageKey) as! CIImage? else {return}
					let imgRef = CoreImageUtilities.shared.hwContext.createCGImage(result, fromRect:result.extent)
					self.imageView.image = UIImage(CGImage:imgRef)
				}
			}
			else
			{
				self.imageView.layer.borderWidth = 0.0
				self.imageView.image = self.image
			}
		}
	}

	// MARK: - Initializers
	override init(frame: CGRect)
	{
		super.init(frame:frame)
		self.backgroundColor = UIColor.fromRGB(0xECECEC)
		self.isAccessibilityElement = true

		self.imageView = UIImageView(frame:CGRect(0.0, 0.0, frame.width, frame.height - 20.0))
		self.imageView.isAccessibilityElement = false
		self.imageView.backgroundColor = UIColor.lightGrayColor()
		self.imageView.layer.borderColor = UIColor.fromRGB(0x444444).CGColor
		self.image = nil
		self.contentView.addSubview(self.imageView)

		self.label = UILabel(frame:CGRect(2.0, self.imageView.frame.bottom, frame.width - 4.0, 20.0))
		self.label.isAccessibilityElement = false
		self.label.backgroundColor = self.backgroundColor
		self.label.textAlignment = .Center
		self.label.textColor = UIColor.fromRGB(0x444444)
		self.label.font = UIFont(name:"AvenirNextCondensed-Medium", size:10.0)
		self.contentView.addSubview(self.label)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	override var selected: Bool
	{
		didSet
		{
			if self.selected
			{
				self.imageView.layer.borderWidth = 0.5
			}
			else
			{
				self.imageView.layer.borderWidth = 0.0
				self.imageView.image = self.image
			}
		}
	}

	override var highlighted: Bool
	{
		didSet
		{
			if self.highlighted
			{
				self.imageView.layer.borderWidth = 0.5
			}
			else
			{
				self.imageView.layer.borderWidth = 0.0
				self.imageView.image = self.image
			}
		}
	}
}
