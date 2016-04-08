// TrackTableViewCell.swift
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


final class TrackTableViewCell : UITableViewCell
{
	// MARK: - Properties
	// Track number
	private(set) var lblTrack: UILabel!
	// Track title
	private(set) var lblTitle: UILabel!
	// Track duration
	private(set) var lblDuration: UILabel!
	// Image to indicate play / pause state
	private(set) var ivPlayback: UIImageView!

	// MARK: - Initializers
	override init(style: UITableViewCellStyle, reuseIdentifier: String?)
	{
		super.init(style:style, reuseIdentifier:reuseIdentifier)
		self.backgroundColor = UIColor.fromRGB(0xECECEC)
		let width = UIScreen.mainScreen().bounds.width // for some reason frame.size always is 320x44
		let height = CGFloat(44.0)
		let margin = CGFloat(8.0)

		self.lblTrack = UILabel(frame:CGRect(margin, (height - 14.0) * 0.5, 18.0, 14.0))
		self.lblTrack.isAccessibilityElement = false
		self.lblTrack.font = UIFont(name:"HelveticaNeue", size:10.0)
		self.lblTrack.textColor = UIColor.fromRGB(0x444444)
		self.lblTrack.textAlignment = .Center
		self.contentView.addSubview(self.lblTrack)

		self.lblTitle = UILabel(frame:CGRect(34.0, (height - 18.0) * 0.5, 100.0, 18.0))
		self.lblTitle.isAccessibilityElement = false
		self.lblTitle.font = UIFont(name:"HelveticaNeue-Medium", size:14.0)
		self.lblTitle.textColor = UIColor.fromRGB(0x444444)
		self.lblTitle.textAlignment = .Left
		self.contentView.addSubview(self.lblTitle)

		self.lblDuration = UILabel(frame:CGRect(width - 32.0 - margin, (height - 14.0) * 0.5, 32.0, 14.0))
		self.lblDuration.isAccessibilityElement = false
		self.lblDuration.font = UIFont(name:"HelveticaNeue-Light", size:10.0)
		self.lblDuration.textColor = UIColor.fromRGB(0x444444)
		self.lblDuration.textAlignment = .Right
		self.contentView.addSubview(self.lblDuration)

		self.ivPlayback = UIImageView(frame:CGRect(margin, (height - 20.0) * 0.5, 20.0, 20.0))
		self.ivPlayback.isAccessibilityElement = false
		self.contentView.addSubview(self.ivPlayback)
	}

	required init?(coder aDecoder: NSCoder)
	{
	    fatalError("init(coder:) has not been implemented")
	}
}
