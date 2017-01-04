// TrackTableViewCell.swift
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


final class TrackTableViewCell : UITableViewCell
{
	// MARK: - Public properties
	// Track number
	@IBOutlet private(set) var lblTrack: UILabel!
	// Track title
	@IBOutlet private(set) var lblTitle: UILabel!
	// Track duration
	@IBOutlet private(set) var lblDuration: UILabel!
	// Separator
	@IBOutlet private(set) var separator: UIView!

	// MARK: - Initializers
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}

	override func setSelected(_ selected: Bool, animated: Bool)
	{
		super.setSelected(selected, animated: animated)

		if selected
		{
			self.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
			contentView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		}
		else
		{
			self.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
			contentView.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		}
	}

	override func setHighlighted(_ highlighted: Bool, animated: Bool)
	{
		super.setHighlighted(highlighted, animated: animated)

		if highlighted
		{
			self.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
			contentView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		}
		else
		{
			self.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
			contentView.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		}
	}
}
