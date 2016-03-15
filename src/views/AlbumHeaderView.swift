// AlbumHeaderView.swift
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


final class AlbumHeaderView : UIView
{
	// MARK: - Properties
	// Album cover
	private(set) var image: UIImage!
	// Album title
	private(set) var lblTitle: TopAlignedLabel!
	// Album artist
	private(set) var lblArtist: UILabel!
	// Album genre
	private(set) var lblGenre: UILabel!
	// Album year
	private(set) var lblYear: UILabel!
	// Size of the cover
	var coverSize: CGSize! {
		didSet {
			self.lblTitle.frame = CGRect(coverSize.width + 4.0, 4.0, self.width - (coverSize.width + 8.0), 40.0)
			self.lblArtist.frame = CGRect(coverSize.width + 4.0, self.lblTitle.bottom + 4.0, self.width - (coverSize.width + 8.0), 18.0)
			self.lblGenre.frame = CGRect(coverSize.width + 4.0, self.bounds.bottom - 20.0, 100.0, 16.0)
			self.lblYear.frame = CGRect(self.bounds.right - 4.0 - 48.0, self.bounds.bottom - 20.0, 48.0, 16.0)
		}
	}

	// MARK: - Initializers
	override init(frame: CGRect)
	{
		super.init(frame:frame)

		self.backgroundColor = UIColor.grayColor()
		self.isAccessibilityElement = true

		self.lblTitle = TopAlignedLabel(frame:CGRectZero)
		self.lblTitle.font = UIFont(name:"GillSans-Bold", size:16.0)
		self.lblTitle.backgroundColor = UIColor.clearColor()
		self.lblTitle.numberOfLines = 2
		self.lblTitle.isAccessibilityElement = false
		self.addSubview(self.lblTitle)

		self.lblArtist = UILabel(frame:CGRectZero)
		self.lblArtist.font = UIFont(name:"GillSans", size:14.0)
		self.lblArtist.backgroundColor = UIColor.clearColor()
		self.lblArtist.numberOfLines = 1
		self.lblArtist.isAccessibilityElement = false
		self.addSubview(self.lblArtist)

		self.lblGenre = UILabel(frame:CGRectZero)
		self.lblGenre.font = UIFont(name:"GillSans-Light", size:12.0)
		self.lblGenre.backgroundColor = UIColor.clearColor()
		self.lblGenre.numberOfLines = 1
		self.lblGenre.isAccessibilityElement = false
		self.addSubview(self.lblGenre)

		self.lblYear = UILabel(frame:CGRectZero)
		self.lblYear.font = UIFont(name:"GillSans-Light", size:12.0)
		self.lblYear.backgroundColor = UIColor.clearColor()
		self.lblYear.numberOfLines = 1
		self.lblYear.textAlignment = .Right
		self.lblYear.isAccessibilityElement = false
		self.addSubview(self.lblYear)
	}

	required init?(coder aDecoder: NSCoder)
	{
	    fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Drawing
	override func drawRect(dirtyRect: CGRect)
	{
		guard let _ = self.image else {return}
		let imageRect = CGRect(CGPointZero, self.coverSize)
		self.image.drawInRect(imageRect, blendMode:.SourceAtop, alpha:1.0)

		let context = UIGraphicsGetCurrentContext()
		CGContextSaveGState(context)
		CGContextClipToRect(context, imageRect)

		let startPoint = CGPoint(CGRectGetMinX(imageRect), CGRectGetMidY(imageRect))
		let endPoint = CGPoint(CGRectGetMaxX(imageRect), CGRectGetMidY(imageRect))
		let color = self.backgroundColor!
		let gradientColors: [CGColorRef] = [color.colorWithAlphaComponent(0.05).CGColor, color.colorWithAlphaComponent(0.75).CGColor, color.colorWithAlphaComponent(0.9).CGColor]
		let locations: [CGFloat] = [0.0, 0.9, 1.0]
		let gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), gradientColors, locations)
		CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, [.DrawsBeforeStartLocation, .DrawsAfterEndLocation])
		CGContextRestoreGState(context)
	}

	// MARK: - Public
	func updateHeaderWithAlbum(album: Album)
	{
		guard let coverURL = album.localCoverURL else {return}
		var image = UIImage(contentsOfFile:coverURL.path!)
		if image == nil
		{
			image = UIImage(named:"default-cover")
		}
		self.image = image

		let x = KawaiiColors(image:image!, precision:8, samplingEdge:.Right)
		x.analyze()
		self.backgroundColor = x.edgeColor
		self.lblTitle.textColor = x.primaryColor
		self.lblArtist.textColor = x.secondaryColor
		self.lblGenre.textColor = x.thirdColor
		self.lblYear.textColor = x.thirdColor
	
		self.setNeedsDisplay()

		let s = album.name as NSString
		let width = self.frame.width - (self.coverSize.width + 8.0)
		let r = s.boundingRectWithSize(CGSize(width, 40.0), options:.UsesLineFragmentOrigin, attributes:[NSFontAttributeName : self.lblTitle.font], context:nil)
		self.lblTitle.frame = CGRect(self.coverSize.width + 4.0, 4.0, ceil(r.width), ceil(r.height))
		self.lblArtist.frame = CGRect(self.coverSize.width + 4.0, self.lblTitle.bottom + 4.0, self.width - (self.coverSize.width + 8.0), 18.0)

		self.lblTitle.text = album.name
		self.lblArtist.text = album.artist
		self.lblGenre.text = album.genre
		self.lblYear.text = album.year

		// Accessibility
		var stra = "\(album.name) \(NYXLocalizedString("lbl_by")) \(album.artist)\n"
		if let tracks = album.songs
		{
			stra += "\(tracks.count) \(NYXLocalizedString("lbl_track"))\(tracks.count > 1 ? "s" : "")\n"
			var duration = UInt(0)
			for track in tracks
			{
				duration += track.duration.seconds
			}
			let minutes = duration / 60
			stra += "\(minutes) \(NYXLocalizedString("lbl_minute"))\(minutes > 1 ? "s" : "")\n"
		}
		self.accessibilityLabel = stra
	}
}
