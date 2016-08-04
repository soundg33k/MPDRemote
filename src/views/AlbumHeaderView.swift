// AlbumHeaderView.swift
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
			lblTitle.frame = CGRect(coverSize.width + 4.0, 4.0, width - (coverSize.width + 8.0), 40.0)
			lblArtist.frame = CGRect(coverSize.width + 4.0, lblTitle.bottom + 4.0, width - (coverSize.width + 8.0), 18.0)
			lblGenre.frame = CGRect(coverSize.width + 4.0, bounds.bottom - 20.0, 100.0, 16.0)
			lblYear.frame = CGRect(bounds.right - 4.0 - 48.0, bounds.bottom - 20.0, 48.0, 16.0)
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
		guard let _ = image else {return}
		let imageRect = CGRect(CGPointZero, coverSize)
		image.drawInRect(imageRect, blendMode:.SourceAtop, alpha:1.0)

		let context = UIGraphicsGetCurrentContext()
		CGContextSaveGState(context)
		CGContextClipToRect(context, imageRect)

		let startPoint = CGPoint(CGRectGetMinX(imageRect), CGRectGetMidY(imageRect))
		let endPoint = CGPoint(CGRectGetMaxX(imageRect), CGRectGetMidY(imageRect))
		let color = backgroundColor!
		let gradientColors: [CGColorRef] = [color.colorWithAlphaComponent(0.05).CGColor, color.colorWithAlphaComponent(0.75).CGColor, color.colorWithAlphaComponent(0.9).CGColor]
		let locations: [CGFloat] = [0.0, 0.9, 1.0]
		let gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), gradientColors, locations)
		CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, [.DrawsBeforeStartLocation, .DrawsAfterEndLocation])
		CGContextRestoreGState(context)
	}

	// MARK: - Public
	func updateHeaderWithAlbum(album: Album)
	{
		// Set cover
		var image: UIImage? = nil
		if let coverURL = album.localCoverURL
		{
			if let cover = UIImage(contentsOfFile:coverURL.path!)
			{
				image = cover
			}
			else
			{
				let coverSize = NSKeyedUnarchiver.unarchiveObjectWithData(NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefCoverSize)!) as! NSValue
				image = generateCoverForAlbum(album, size: coverSize.CGSizeValue())
			}
		}
		else
		{
			let coverSize = NSKeyedUnarchiver.unarchiveObjectWithData(NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefCoverSize)!) as! NSValue
			image = generateCoverForAlbum(album, size: coverSize.CGSizeValue())
		}
		self.image = image

		// Analyze colors
		let x = KawaiiColors(image:image!, precision:8, samplingEdge:.Right)
		x.analyze()
		backgroundColor = x.edgeColor
		lblTitle.textColor = x.primaryColor
		lblTitle.backgroundColor = backgroundColor
		lblArtist.textColor = x.secondaryColor
		lblArtist.backgroundColor = backgroundColor
		lblGenre.textColor = x.thirdColor
		lblGenre.backgroundColor = backgroundColor
		lblYear.textColor = x.thirdColor
		lblYear.backgroundColor = backgroundColor

		setNeedsDisplay()

		// Update frame for title / artist
		let s = album.name as NSString
		let width = frame.width - (coverSize.width + 8.0)
		let r = s.boundingRectWithSize(CGSize(width, 40.0), options:.UsesLineFragmentOrigin, attributes:[NSFontAttributeName : lblTitle.font], context:nil)
		lblTitle.frame = CGRect(coverSize.width + 4.0, 4.0, ceil(r.width), ceil(r.height))
		lblArtist.frame = CGRect(coverSize.width + 4.0, lblTitle.bottom + 4.0, width - (coverSize.width + 8.0), 18.0)

		lblTitle.text = album.name
		lblArtist.text = album.artist
		lblGenre.text = album.genre
		lblYear.text = album.year

		// Accessibility
		var stra = "\(album.name) \(NYXLocalizedString("lbl_by")) \(album.artist)\n"
		if let tracks = album.songs
		{
			stra += "\(tracks.count) \(NYXLocalizedString("lbl_track"))\(tracks.count > 1 ? "s" : "")\n"
			let total = tracks.reduce(Duration(seconds:0)){$0 + $1.duration}
			let minutes = total.seconds / 60
			stra += "\(minutes) \(NYXLocalizedString("lbl_minute"))\(minutes > 1 ? "s" : "")\n"
		}
		accessibilityLabel = stra
	}
}
