// HeaderScrollView.swift
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


protocol HeaderScrollViewDelegate : class
{
	func requestNextAlbum() -> Album?
	func requestPreviousAlbum() -> Album?
	func shouldShowNextAlbum() -> Bool
	func shouldShowPreviousAlbum() -> Bool
}


final class HeaderScrollView : UIScrollView
{
	// MARK: - Public properties
	// Delegate
	weak var navDelegate: HeaderScrollViewDelegate? = nil
	// Current album view
	private(set) var mainView: AlbumHeaderView! = nil
	// Previous or next album view
	private(set) var sideView: AlbumHeaderView! = nil
	// Size of the cover
	private(set) var coverWidth = CGFloat(0.0)

	// MARK: - Private properties
	// Scroll direction changed, flag
	private var directionChanged = false
	// Scroll direction, flag
	private var fromLeft = false
	// Delegate can display next header, flag
	private var canDisplayNext = false
	// Delegate can display previous header, flag
	private var canDisplayPrevious = false

	// MARK: - Initializers
	override init(frame: CGRect)
	{
		super.init(frame:frame)

		self.coverWidth = frame.height
		self.scrollEnabled = true
		self.bounces = true
		self.alwaysBounceHorizontal = true
		self.alwaysBounceVertical = false
		self.showsHorizontalScrollIndicator = false
		self.showsVerticalScrollIndicator = false
		self.scrollsToTop = false
		self.delegate = self
		self.backgroundColor = UIColor.fromRGB(0xECECEC)

		self.mainView = AlbumHeaderView(frame:CGRect(0.0, 0.0, frame.width, frame.height))
		self.mainView.coverSize = CGSize(self.coverWidth, self.coverWidth)
		self.addSubview(self.mainView)

		self.sideView = AlbumHeaderView(frame:CGRect(frame.size.width, 0.0, frame.size))
		self.sideView.coverSize = CGSize(self.coverWidth, self.coverWidth)
		self.addSubview(self.sideView)

		self.contentSize = frame.size
	}

	required init?(coder aDecoder: NSCoder)
	{
	    fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Public
	func itemChanged()
	{
		let animation = CATransition()
		animation.duration = 0.5
		animation.type = kCATransitionPush
		animation.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
		if (self.fromLeft)
		{
			animation.subtype = kCATransitionFromLeft
			self.layer.addAnimation(animation, forKey:"io.whine.mpdremote.transition.left")
		}
		else
		{
			animation.subtype = kCATransitionFromRight
			self.layer.addAnimation(animation, forKey:"io.whine.mpdremote.transition.right")
		}
		self.contentInset = UIEdgeInsetsZero
	}
}

// MARK: - UIScrollViewDelegate
extension HeaderScrollView : UIScrollViewDelegate
{
	func scrollViewWillBeginDragging(scrollView: UIScrollView)
	{
		self.directionChanged = true
	}

	func scrollViewDidScroll(scrollView: UIScrollView)
	{
		let x = scrollView.contentOffset.x
		if (x > 0.0) // Next
		{
			if self.directionChanged
			{
				self.sideView.frame.x = self.frame.width
				if let album = self.navDelegate?.requestNextAlbum()
				{
					self.sideView.updateHeaderWithAlbum(album)
				}
				else
				{
					self.sideView.lblTitle.text = ""
					self.sideView.lblArtist.text = ""
					self.sideView.lblGenre.text = ""
					self.sideView.lblYear.text = ""
				}
			}
			self.canDisplayNext = (self.sideView.lblTitle.text?.length > 0) && (x >= self.coverWidth)
		}
		else // previous
		{
			if self.directionChanged
			{
				self.sideView.frame.x = -self.frame.width
				if let album = self.navDelegate?.requestPreviousAlbum()
				{
					self.sideView.updateHeaderWithAlbum(album)
				}
				else
				{
					self.sideView.lblTitle.text = ""
					self.sideView.lblArtist.text = ""
					self.sideView.lblGenre.text = ""
					self.sideView.lblYear.text = ""
				}
			}
			self.canDisplayPrevious = (self.sideView.lblTitle.text?.length > 0) && (x <= -self.coverWidth)
		}
		self.directionChanged = false
	}

	func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool)
	{
		if scrollView.contentOffset.x >= self.coverWidth // next
		{
			if self.canDisplayNext
			{
				scrollView.contentInset = UIEdgeInsets(top:0.0, left:0.0, bottom:0.0, right:scrollView.frame.width)
				self.fromLeft = false
				if !(self.navDelegate?.shouldShowNextAlbum())!
				{
					scrollView.contentInset = UIEdgeInsetsZero
				}
			}
		}
		else if  scrollView.contentOffset.x <= -self.coverWidth // previous
		{
			if self.canDisplayPrevious
			{
				scrollView.contentInset = UIEdgeInsets(top:0.0, left:-scrollView.frame.width, bottom:0.0, right:0.0)
				self.fromLeft = true
				if !(self.navDelegate?.shouldShowPreviousAlbum())!
				{
					scrollView.contentInset = UIEdgeInsetsZero
				}
			}
		}
	}

	func scrollViewWillBeginDecelerating(scrollView: UIScrollView)
	{
		if scrollView.contentOffset.x >= self.coverWidth // next
		{
			if self.canDisplayNext
			{
				scrollView.setContentOffset(scrollView.contentOffset, animated:true)
			}
		}
		else if  scrollView.contentOffset.x <= -self.coverWidth // previous
		{
			if self.canDisplayPrevious
			{
				scrollView.setContentOffset(scrollView.contentOffset, animated:true)
			}
		}
	}
}
