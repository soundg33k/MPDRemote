// RootCollectionViewCell.swift
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


final class RootCollectionViewCell : UICollectionViewCell
{
	// MARK: - Properties
	// Album cover
	private(set) var imageView: UIImageView! = nil
	// Album name
	private(set) var label: UILabel! = nil
	// Original image set
	var image: UIImage?
	{
		didSet
		{
			imageView.image = image
		}
	}
	// Flag to indicate that the cell is being long pressed
	var longPressed: Bool = false
	{
		didSet
		{
			if longPressed
			{
				label.font = UIFont(name:"AvenirNextCondensed-DemiBold", size:10.0)
				imageView.layer.borderWidth = 0.5
				if let img = image
				{
					guard let ciimg = CIImage(image:img) else {return}
					guard let filter = CIFilter(name:"CIUnsharpMask") else {return}
					filter.setDefaults()
					filter.setValue(ciimg, forKey:kCIInputImageKey)
					guard let result = filter.value(forKey: kCIOutputImageKey) as! CIImage? else {return}
					imageView.image = UIImage(ciImage:result)
				}
			}
			else
			{
				label.font = UIFont(name:"AvenirNextCondensed-Medium", size:10.0)
				imageView.layer.borderWidth = 0.0
				imageView.image = image
			}
		}
	}

	// MARK: - Initializers
	override init(frame: CGRect)
	{
		super.init(frame:frame)
		self.backgroundColor = UIColor.fromRGB(0xECECEC)
		self.isAccessibilityElement = true

		self.imageView = UIImageView(frame:CGRect(CGPoint.zero, frame.width, frame.height - 20.0))
		self.imageView.isAccessibilityElement = false
		self.imageView.layer.borderColor = UIColor.fromRGB(0x444444).cgColor
		self.image = nil
		self.contentView.addSubview(self.imageView)

		self.label = UILabel(frame:CGRect(0.0, self.imageView.bottom, frame.width, 20.0))
		self.label.isAccessibilityElement = false
		self.label.backgroundColor = self.backgroundColor
		self.label.textAlignment = .center
		self.label.textColor = UIColor.fromRGB(0x444444)
		self.label.font = UIFont(name:"AvenirNextCondensed-Medium", size:10.0)
		self.contentView.addSubview(self.label)
	}

	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder:aDecoder)
		self.backgroundColor = UIColor.fromRGB(0xECECEC)
		self.isAccessibilityElement = true

		self.imageView = UIImageView(frame:CGRect(CGPoint.zero, frame.width, frame.height - 20.0))
		self.imageView.isAccessibilityElement = false
		self.imageView.layer.borderColor = UIColor.fromRGB(0x444444).cgColor
		self.image = nil
		self.contentView.addSubview(self.imageView)

		self.label = UILabel(frame:CGRect(0.0, self.imageView.bottom, frame.width, 20.0))
		self.label.isAccessibilityElement = false
		self.label.backgroundColor = self.backgroundColor
		self.label.textAlignment = .center
		self.label.textColor = UIColor.fromRGB(0x444444)
		self.label.font = UIFont(name:"AvenirNextCondensed-Medium", size:10.0)
		self.contentView.addSubview(self.label)
	}

	// MARK: - Overrides
	override var isSelected: Bool
	{
		didSet
		{
			if isSelected
			{
				label.font = UIFont(name:"AvenirNextCondensed-DemiBold", size:10.0)
				imageView.layer.borderWidth = 0.5
			}
			else
			{
				label.font = UIFont(name:"AvenirNextCondensed-Medium", size:10.0)
				imageView.layer.borderWidth = 0.0
			}
		}
	}

	override var isHighlighted: Bool
	{
		didSet
		{
			if isHighlighted
			{
				label.font = UIFont(name:"AvenirNextCondensed-DemiBold", size:10.0)
				imageView.layer.borderWidth = 0.5
			}
			else
			{
				label.font = UIFont(name:"AvenirNextCondensed-Medium", size:10.0)
				imageView.layer.borderWidth = 0.0
			}
		}
	}
}
