// AlbumTableViewCell.swift
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


final class AlbumTableViewCell : UITableViewCell
{
	// MARK: - Properties
	// Album cover
	private(set) var coverView: UIImageView!
	// Album name
	private(set) var lblAlbum: UILabel!
	// Separator
	private(set) var separator: UIView!

	// MARK: - Initializers
	override init(style: UITableViewCellStyle, reuseIdentifier: String?)
	{
		super.init(style:style, reuseIdentifier:reuseIdentifier)
		self.backgroundColor = UIColor.fromRGB(0xECECEC)
		let width = UIScreen.mainScreen().bounds.width // for some reason frame.size always is 320x44
		let height = CGFloat(74.0)
		let coverWH = height - 10.0

		self.coverView = UIImageView(frame:CGRect(5.0, (height - coverWH) * 0.5, coverWH, coverWH))
		self.coverView.isAccessibilityElement = false
		self.contentView.addSubview(self.coverView)

		self.lblAlbum = TopAlignedLabel(frame:CGRect(self.coverView.right + 10.0, self.coverView.y, (width - self.coverView.right - 40.0), 40.0))
		self.lblAlbum.isAccessibilityElement = false
		self.lblAlbum.font = UIFont(name:"HelveticaNeue-Medium", size:14.0)
		self.lblAlbum.textColor = UIColor.fromRGB(0x444444)
		self.lblAlbum.textAlignment = .Left
		self.lblAlbum.numberOfLines = 2
		self.contentView.addSubview(self.lblAlbum)

		self.separator = UIView(frame:CGRect(0.0, height - 1.0, width, 1.0))
		self.separator.isAccessibilityElement = false
		self.separator.backgroundColor = UIColor.fromRGB(0xCCCCCC)
		self.contentView.addSubview(self.separator)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
}
