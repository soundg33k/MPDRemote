// TypeChoiceView.swift
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


protocol TypeChoiceViewDelegate : class
{
	func didSelectType(_ type: DisplayType)
}


final class TypeChoiceView : UIView
{
	// MARK: - Properties
	// Delegate
	weak var delegate: TypeChoiceViewDelegate? = nil
	// TableView
	private(set) var tableView: UITableView! = nil

	// MARK: - Initializers
	override init(frame: CGRect)
	{
		super.init(frame:frame)
		self.backgroundColor = UIColor.fromRGB(0x131313)

		// TableView
		self.tableView = UITableView(frame:CGRect(CGPoint.zero, frame.size), style:.plain)
		self.tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier:"io.whine.mpdremote.cell.type")
		self.tableView.dataSource = self
		self.tableView.delegate = self
		self.tableView.backgroundColor = UIColor.fromRGB(0x131313)
		self.tableView.showsVerticalScrollIndicator = false
		self.tableView.scrollsToTop = false
		self.tableView.isScrollEnabled = false
		self.tableView.separatorStyle = .none
		self.tableView.rowHeight = 44.0
		self.addSubview(self.tableView)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}
}

// MARK: - UITableViewDelegate
extension TypeChoiceView : UITableViewDataSource
{
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return 3
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "io.whine.mpdremote.cell.type", for:indexPath)
		cell.selectionStyle = .none
		cell.backgroundColor = UIColor.fromRGB(0x131313)
		cell.textLabel?.textAlignment = .center
		var title = ""
		var selected = false
		switch (indexPath.row)
		{
			case 0:
				title = NYXLocalizedString("lbl_albums")
				selected = UserDefaults.standard().integer(forKey: kNYXPrefDisplayType) == DisplayType.albums.rawValue
			case 1:
				title = NYXLocalizedString("lbl_artists")
				selected = UserDefaults.standard().integer(forKey: kNYXPrefDisplayType) == DisplayType.artists.rawValue
			case 2:
				title = NYXLocalizedString("lbl_genres")
				selected = UserDefaults.standard().integer(forKey: kNYXPrefDisplayType) == DisplayType.genres.rawValue
			default:
				break
		}
		cell.textLabel?.text = title
		if selected
		{
			cell.textLabel?.font = UIFont(name:"HelveticaNeue-Medium", size:16.0)
			cell.textLabel?.textColor = UIColor.fromRGB(0xCC0000)
		}
		else
		{
			cell.textLabel?.font = UIFont(name:"HelveticaNeue", size:15.0)
			cell.textLabel?.textColor = UIColor.fromRGB(0xECECEC)
		}
		return cell
	}
}

// MARK: - UITableViewDelegate
extension TypeChoiceView : UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		switch (indexPath.row)
		{
			case 0:
				delegate?.didSelectType(.albums)
			case 1:
				delegate?.didSelectType(.artists)
			case 2:
				delegate?.didSelectType(.genres)
			default:
				break
		}
		tableView.deselectRow(at: indexPath, animated:false)
	}

	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
	{
		// lil bounce animation
		let cellRect = tableView.rectForRow(at: indexPath)

		cell.frame = CGRect(cell.x, cell.y + tableView.height, cell.width, cell.height)

		UIView.animate(withDuration: 0.5, delay:0.1 * Double(indexPath.row), usingSpringWithDamping:0.8, initialSpringVelocity:10.0, options:UIViewAnimationOptions(), animations:{
			cell.frame = cellRect
		}, completion:nil)
	}
}
