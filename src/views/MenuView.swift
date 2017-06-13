// MenuView.swift
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


private var __startX: CGFloat = 0.0
private let __numberOfRows = 4
public let __minBackgroundOpacity: CGFloat = 0.3


protocol MenuViewDelegate : class
{
	func menuViewShouldClose(_ menuView: UIView)
	func menuViewDidClose(_ menuView: UIView)
	func menuViewDidMove(_ menuView: UIView)
}


final class MenuView : UIView
{
	// MARK: - Public properties
	// Delegate
	weak var menuDelegate: MenuViewDelegate? = nil
	// Is visible flag
	var visible = false
	{
		didSet
		{
			if let p = pan
			{
				p.isEnabled = visible
			}
		}
	}

	// MARK: - Private properties
	// TableView
	fileprivate var tableView: UITableView! = nil
	// Pan gesture
	private var pan: UIPanGestureRecognizer! = nil
	// Minimum x for the menu
	private var _menuMinX: CGFloat = 0.0

	// MARK: - Initializers
	override init(frame: CGRect)
	{
		super.init(frame:frame)
		self.isUserInteractionEnabled = true
		self.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		_menuMinX = -(frame.size.width + 2.0)

		// TableView
		self.tableView = UITableView(frame: CGRect(.zero, frame.size), style: .plain)
		self.tableView.register(MenuViewTableViewCell.classForCoder(), forCellReuseIdentifier: "fr.whine.mpdremote.cell.menu")
		self.tableView.dataSource = self
		self.tableView.delegate = self
		self.tableView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		self.tableView.showsVerticalScrollIndicator = false
		self.tableView.scrollsToTop = false
		self.tableView.isScrollEnabled = false
		self.tableView.separatorColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		self.tableView.separatorInset = .zero
		self.tableView.layoutMargins = .zero
		self.addSubview(self.tableView)

		// Pan
		self.pan = UIPanGestureRecognizer(target: self, action: #selector(MenuView.pan(_:)))
		self.pan.delegate = self
		self.pan.isEnabled = false
		self.addGestureRecognizer(self.pan)

		self.tableView.reloadData()
	}

	required init?(coder aDecoder: NSCoder)
	{
	    fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Gesture
	func pan(_ gest: UIPanGestureRecognizer)
	{
		switch (gest.state)
		{
			case .began:
				__startX = x
			case .changed:
				let translationX = gest.translation(in: gest.view).x
				var tmp = __startX + translationX
				if (tmp > 0.0)
				{
					tmp = 0.0
				}
				else if (translationX < -width)
				{
					tmp = -width
				}
				x = tmp
			self.menuDelegate?.menuViewDidMove(self)
			case .ended:
				let cmp = x
				let limit = (_menuMinX / 2.6)
				let visible = (cmp >= limit)
				UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseOut, animations: {
					self.x = visible ? 0.0 : self._menuMinX
				}, completion:{ finished in
					self.visible = visible
					if visible == false
					{
						self.menuDelegate?.menuViewDidClose(self)
					}
				})
			default:
				break
		}
	}
}

// MARK: - UITableViewDataSource
extension MenuView : UITableViewDataSource
{
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return __numberOfRows + 1
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "fr.whine.mpdremote.cell.menu", for: indexPath) as! MenuViewTableViewCell
		
		var selected = false
		var image: UIImage! = nil
		switch (indexPath.row)
		{
			case 0:
				cell.accessibilityLabel = NYXLocalizedString("lbl_section_home")
				image = #imageLiteral(resourceName: "img-home")
				selected = (APP_DELEGATE().window?.rootViewController === APP_DELEGATE().homeVC)
			case 1:
				cell.accessibilityLabel = NYXLocalizedString("lbl_section_server")
				image = #imageLiteral(resourceName: "img-server")
				selected = (APP_DELEGATE().window?.rootViewController === APP_DELEGATE().serverVC)
			case 2:
				cell.accessibilityLabel = NYXLocalizedString("lbl_section_settings")
				image = #imageLiteral(resourceName: "img-settings")
				selected = (APP_DELEGATE().window?.rootViewController === APP_DELEGATE().settingsVC)
			case 3:
				cell.accessibilityLabel = NYXLocalizedString("lbl_section_stats")
				image = #imageLiteral(resourceName: "img-stats")
				selected = (APP_DELEGATE().window?.rootViewController === APP_DELEGATE().statsVC)
			default:
				break
		}
		if image != nil
		{
			cell.ivLogo.image = image.withRenderingMode(.alwaysTemplate)
			cell.ivLogo.frame = CGRect(24.0, (cell.height - image.size.height) * 0.5, image.size)
			cell.lblSection.text = cell.accessibilityLabel
			cell.lblSection.frame = CGRect(96.0, (cell.height - cell.lblSection.height) * 0.5, cell.lblSection.size)
		}

		if selected
		{
			cell.ivLogo.tintColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
			cell.lblSection.textColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
			cell.lblSection.font = UIFont.boldSystemFont(ofSize: 13.0)
		}
		else
		{
			cell.ivLogo.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
			cell.lblSection.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
			cell.lblSection.font = UIFont.systemFont(ofSize: 13.0)
		}

		return cell
	}
}

// MARK: - UITableViewDelegate
extension MenuView : UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		tableView.deselectRow(at: indexPath, animated: false)
		var newTopViewController: UIViewController! = nil
		switch (indexPath.row)
		{
			case 0:
				newTopViewController = APP_DELEGATE().homeVC
			case 1:
				newTopViewController = APP_DELEGATE().serverVC
			case 2:
				newTopViewController = APP_DELEGATE().settingsVC
			case 3:
				newTopViewController = APP_DELEGATE().statsVC
			case __numberOfRows:
				return
			default:
				break
		}
		menuDelegate?.menuViewShouldClose(self)
		APP_DELEGATE().window?.rootViewController = newTopViewController

		if newTopViewController === APP_DELEGATE().homeVC
		{
			APP_DELEGATE().window?.bringSubview(toFront: MiniPlayerView.shared)
		}
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		if indexPath.row == __numberOfRows
		{
			return tableView.height
		}
		return 64.0
	}
}

// MARK: - UIGestureRecognizerDelegate
extension MenuView : UIGestureRecognizerDelegate
{
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
	{
		if (tableView.panGestureRecognizer === otherGestureRecognizer)
		{
			return false
		}
		return true
	}
}
