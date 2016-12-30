// RootCollectionViewCell.swift
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


final class RootCollectionViewCell : UICollectionViewCell
{
	// MARK: - Public properties
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
				UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
					self.label.font = UIFont(name: "AvenirNextCondensed-DemiBold", size: 10.0)
					let anim = CABasicAnimation(keyPath: "borderWidth")
					anim.fromValue = 0
					anim.toValue = 1
					anim.duration = CATransaction.animationDuration()
					anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
					self.imageView.layer.add(anim, forKey: "kawaii-anim")
					if let img = self.image
					{
						guard let ciimg = CIImage(image: img) else {return}
						guard let filter = CIFilter(name: "CIUnsharpMask") else {return}
						filter.setDefaults()
						filter.setValue(ciimg, forKey: kCIInputImageKey)
						guard let result = filter.value(forKey: kCIOutputImageKey) as! CIImage? else {return}
						self.imageView.image = UIImage(ciImage: result)
					}
				}, completion:{ finished in
					self.imageView.layer.borderWidth = 1
				})
			}
			else
			{
				UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
					self.label.font = UIFont(name: "AvenirNextCondensed-Medium", size: 10.0)
					let anim = CABasicAnimation(keyPath: "borderWidth")
					anim.fromValue = 1
					anim.toValue = 0
					anim.duration = CATransaction.animationDuration()
					anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
					self.imageView.layer.add(anim, forKey: "kawaii-anim")
					self.imageView.image = self.image
				}, completion:{ finished in
					self.imageView.layer.borderWidth = 0
				})
			}
		}
	}

	// MARK: - Initializers
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		self.backgroundColor = isNightModeEnabled() ? #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1) : #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		self.isAccessibilityElement = true

		self.imageView = UIImageView(frame: CGRect(.zero, frame.width, frame.height - 20.0))
		self.imageView.isAccessibilityElement = false
		self.imageView.backgroundColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
		self.imageView.layer.borderColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1).cgColor
		self.image = nil
		self.contentView.addSubview(self.imageView)

		self.label = UILabel(frame:CGRect(0.0, self.imageView.bottom, frame.width, 20.0))
		self.label.isAccessibilityElement = false
		self.label.backgroundColor = self.backgroundColor
		self.label.textAlignment = .center
		self.label.textColor = isNightModeEnabled() ? #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1) : #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
		self.label.font = UIFont(name: "AvenirNextCondensed-Medium", size: 10.0)
		self.contentView.addSubview(self.label)
	}

	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
		self.backgroundColor = isNightModeEnabled() ? #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1) : #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		self.isAccessibilityElement = true

		self.imageView = UIImageView(frame: CGRect(.zero, frame.width, frame.height - 20.0))
		self.imageView.isAccessibilityElement = false
		self.imageView.backgroundColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
		self.imageView.layer.borderColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1).cgColor
		self.image = nil
		self.contentView.addSubview(self.imageView)

		self.label = UILabel(frame: CGRect(0.0, self.imageView.bottom, frame.width, 20.0))
		self.label.isAccessibilityElement = false
		self.label.backgroundColor = self.backgroundColor
		self.label.textAlignment = .center
		self.label.textColor = isNightModeEnabled() ? #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1) : #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
		self.label.font = UIFont(name: "AvenirNextCondensed-Medium", size: 10.0)
		self.contentView.addSubview(self.label)
	}

	// MARK: - Overrides
	override var isSelected: Bool
	{
		didSet
		{
			if isSelected
			{
				label.font = UIFont(name: "AvenirNextCondensed-DemiBold", size: 10.0)
				imageView.layer.borderWidth = 0.5
			}
			else
			{
				label.font = UIFont(name: "AvenirNextCondensed-Medium", size: 10.0)
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
				label.font = UIFont(name: "AvenirNextCondensed-DemiBold", size: 10.0)
				imageView.layer.borderWidth = 0.5
			}
			else
			{
				label.font = UIFont(name: "AvenirNextCondensed-Medium", size: 10.0)
				imageView.layer.borderWidth = 0.0
			}
		}
	}
}
