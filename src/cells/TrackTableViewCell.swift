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
	private(set) var imgPlayback: UIImageView!

	// MARK: - Initializers
	override init(style: UITableViewCellStyle, reuseIdentifier: String?)
	{
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		self.backgroundColor = UIColor.fromRGB(0xECECEC)

		self.lblTrack = UILabel(frame:CGRect(8.0, (self.height - 14.0) * 0.5, 18.0, 14.0))
		self.lblTrack.font = UIFont(name:"HelveticaNeue", size:10.0)
		self.lblTrack.textAlignment = .Center
		self.lblTrack.textColor = UIColor.fromRGB(0x444444)
		self.lblTrack.isAccessibilityElement = false
		self.contentView.addSubview(self.lblTrack)

		self.lblTitle = UILabel(frame:CGRect(34.0, (self.height - 18.0) * 0.5, 100.0, 18.0))
		self.lblTitle.font = UIFont(name:"HelveticaNeue-Medium", size:14.0)
		self.lblTitle.textColor = UIColor.fromRGB(0x444444)
		self.lblTitle.isAccessibilityElement = false
		self.contentView.addSubview(self.lblTitle)

		self.lblDuration = UILabel(frame:CGRect(self.contentView.bounds.right - 32.0 - 8.0, (self.height - 14.0) * 0.5, 32.0, 14.0))
		self.lblDuration.font = UIFont(name:"HelveticaNeue-Light", size:10.0)
		self.lblDuration.textAlignment = .Right
		self.lblDuration.textColor = UIColor.fromRGB(0x444444)
		self.lblDuration.isAccessibilityElement = false
		self.contentView.addSubview(self.lblDuration)

		self.imgPlayback = UIImageView(frame:CGRect(8.0, (self.height - 20.0) * 0.5, 20.0, 20.0))
		self.contentView.addSubview(self.imgPlayback)
	}

	required init?(coder aDecoder: NSCoder)
	{
	    fatalError("init(coder:) has not been implemented")
	}
}
