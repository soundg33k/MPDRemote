// CollectionViewCell.swift
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


final class CollectionViewCell : UICollectionViewCell
{
	// MARK: - Public properties
	// Album cover
	var imageView: UIImageView! = nil
	// Entity name
	var label: UILabel! = nil
	// Original image set
	var image: UIImage?
	{
		didSet
		{
			imageView.image = image
		}
	}

	var focusedSpacingConstraint: NSLayoutConstraint!


	// MARK: - Initializers
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		self.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
		self.isAccessibilityElement = true

		self.imageView = UIImageView(frame: .zero)
		self.imageView.isAccessibilityElement = false
		self.imageView.backgroundColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
		self.image = nil
		self.contentView.addSubview(self.imageView)

		self.label = UILabel(frame: .zero)
		self.label.isAccessibilityElement = false
		self.label.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
		self.label.textAlignment = .center
		self.label.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		self.label.font = UIFont.boldSystemFont(ofSize: 16.0)
		self.contentView.addSubview(self.label)

		self.imageView.adjustsImageWhenAncestorFocused = true
		self.imageView.clipsToBounds = false
		//self.label.clipsToBounds = false
	}

	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
		self.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
		self.isAccessibilityElement = true

		self.imageView = UIImageView(frame: .zero)
		self.imageView.isAccessibilityElement = false
		self.imageView.backgroundColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
		self.image = nil
		self.contentView.addSubview(self.imageView)

		self.label = UILabel(frame: .zero)
		self.label.isAccessibilityElement = false
		self.label.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
		self.label.textAlignment = .center
		self.label.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		self.label.font = UIFont.boldSystemFont(ofSize: 16.0)
		self.contentView.addSubview(self.label)

		self.imageView.adjustsImageWhenAncestorFocused = true
		self.imageView.clipsToBounds = false
		//self.label.clipsToBounds = false
	}

	override func layoutSubviews()
	{
		self.imageView.frame = CGRect(.zero, frame.width, frame.height - 24.0)
		self.label.frame = CGRect(0.0, self.imageView.bottom, frame.width, 24.0)
		self.label.textAlignment = .center
		self.label.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		self.label.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
		self.label.font = UIFont.boldSystemFont(ofSize: 20.0)
	}

	override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator)
	{
		super.didUpdateFocus(in: context, with: coordinator)

		//self.focusedSpacingConstraint = NSLayoutConstraint(item: imageView.focusedFrameGuide, attribute: .bottomMargin, relatedBy: .equal, toItem: label, attribute: .top, multiplier: 1, constant: 0)
		//self.focusedSpacingConstraint.isActive = self.imageView.isFocused

		self.label.layer.masksToBounds = true
		if context.nextFocusedView == self
		{
			coordinator.addCoordinatedAnimations({
				UIView.animate(withDuration: UIView.inheritedAnimationDuration) {
					self.label.frame = CGRect(0, self.imageView.bottom - self.label.height, self.frame.width, 48.0)
					self.label.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.8)
					self.label.font = UIFont.boldSystemFont(ofSize: 32.0)
					self.label.layer.cornerRadius = 24.0
				}
			}, completion: nil)
		}
		else if context.previouslyFocusedView == self
		{
			coordinator.addCoordinatedAnimations({
				UIView.animate(withDuration: UIView.inheritedAnimationDuration) {
					self.label.frame = CGRect(0.0, self.imageView.bottom, self.frame.width, 24.0)
					self.label.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
					self.label.font = UIFont.boldSystemFont(ofSize: 20.0)
					self.label.layer.cornerRadius = 0
				}
			}, completion: nil)
		}
	}

	// MARK: - Overrides
	/*override var isSelected: Bool
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
	}*/
}
