// MenuView.swift
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


private var __startX = CGFloat(0.0)
private let __numberOfRows = 2


protocol MenuViewDelegate : class
{
	func menuViewShouldClose(menuView: UIView)
	func menuViewDidClose(menuView: UIView)
}


final class MenuView : UIView
{
	// MARK: - Public properties
	// Delegate
	weak var menuDelegate: MenuViewDelegate? = nil
	// Is visible flag
	var visible = false {
		didSet {
			if let p = pan
			{
				p.enabled = visible
			}
		}
	}

	// MARK: - Private properties
	// TableView
	private var tableView: UITableView! = nil
	// Kikoolol
	private var blurEffectView: UIVisualEffectView! = nil
	// Pan gesture
	private var pan: UIPanGestureRecognizer! = nil
	// Minimum x for the menu
	private var _menuMinX = CGFloat(0.0)

	// MARK: - Initializers
	override init(frame: CGRect)
	{
		super.init(frame:frame)
		self.userInteractionEnabled = true
		self.backgroundColor = UIColor.clearColor()
		_menuMinX = -(frame.size.width + 2.0)

		// Blur effect
		self.blurEffectView = UIVisualEffectView(effect:UIBlurEffect(style:.Light))
		self.blurEffectView.frame = self.bounds
		self.layer.shadowColor = UIColor.fromRGB(0xAAAAAA).CGColor
		self.layer.shadowPath = UIBezierPath(rect:CGRect(frame.width - 1.5, 4.0, 2.0, frame.height)).CGPath
		self.layer.shadowRadius = 1.0
		self.layer.shadowOpacity = 1.0
		self.layer.masksToBounds = false
		self.addSubview(self.blurEffectView)

		// TableView
		self.tableView = UITableView(frame:CGRect(CGPointZero, frame.size), style:.Plain)
		self.tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier:"io.whine.mpdremote.cell.menu")
		self.tableView.dataSource = self
		self.tableView.delegate = self
		self.tableView.backgroundColor = UIColor.clearColor()
		self.tableView.showsVerticalScrollIndicator = false
		self.tableView.scrollsToTop = false
		self.tableView.scrollEnabled = false
		self.tableView.separatorColor = UIColor.blackColor()
		self.tableView.separatorInset = UIEdgeInsetsZero
		self.tableView.layoutMargins = UIEdgeInsetsZero
		self.blurEffectView.contentView.addSubview(self.tableView)

		// Pan
		self.pan = UIPanGestureRecognizer(target:self, action:#selector(MenuView.pan(_:)))
		self.pan.delegate = self
		self.pan.enabled = false
		self.addGestureRecognizer(self.pan)

		self.tableView.reloadData()
	}

	required init?(coder aDecoder: NSCoder)
	{
	    fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Gesture
	func pan(gest: UIPanGestureRecognizer)
	{
		switch (gest.state)
		{
			case .Began:
				__startX = self.x
			case .Changed:
				let translationX = gest.translationInView(gest.view).x
				var tmp = __startX + translationX
				if (tmp > 0.0)
				{
					tmp = 0.0
				}
				else if (translationX < -self.width)
				{
					tmp = -self.width
				}
				self.x = tmp
			case .Ended:
				let cmp = self.x
				let limit = (self._menuMinX / 2.6)
				UIView.animateWithDuration(0.35, delay:0.0, options:.CurveEaseOut, animations:{
					self.x = (cmp >= limit) ? 0.0 : self._menuMinX
				}, completion:{ finished in
					let v = (cmp >= limit)
					self.visible = v
					if !v
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
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return __numberOfRows + 1
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCellWithIdentifier("io.whine.mpdremote.cell.menu", forIndexPath:indexPath)
		cell.selectionStyle = .None
		cell.backgroundColor = UIColor.clearColor()
		cell.textLabel?.textColor = UIColor.blackColor()
		cell.layoutMargins = UIEdgeInsetsZero
		var title = ""
		var selected = false
		switch (indexPath.row)
		{
			case 0:
				title = NYXLocalizedString("lbl_section_home")
				cell.imageView?.image = UIImage(named:"img-home")
				selected = (APP_DELEGATE().window!.rootViewController === APP_DELEGATE().homeVC)
			case 1:
				title = NYXLocalizedString("lbl_section_server")
				cell.imageView?.image = UIImage(named:"img-server")
				selected = (APP_DELEGATE().window!.rootViewController === APP_DELEGATE().serverVC)
			case __numberOfRows:
				break
			default:
				break
		}
		cell.textLabel?.text = title
		cell.textLabel?.font = selected ? UIFont.boldSystemFontOfSize(14.0) : UIFont.systemFontOfSize(14.0)
		return cell
	}
}

// MARK: - UITableViewDelegate
extension MenuView : UITableViewDelegate
{
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		tableView.deselectRowAtIndexPath(indexPath, animated:false)
		var newTopViewController: UIViewController! = nil
		switch (indexPath.row)
		{
			case 0:
				newTopViewController = APP_DELEGATE().homeVC
			case 1:
				newTopViewController = APP_DELEGATE().serverVC
			case __numberOfRows:
				return
			default:
				break
		}
		self.menuDelegate?.menuViewShouldClose(self)
		APP_DELEGATE().window!.rootViewController = newTopViewController

		if newTopViewController === APP_DELEGATE().homeVC
		{
			APP_DELEGATE().window?.bringSubviewToFront(MiniPlayerView.shared)
		}
	}

	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
	{
		if indexPath.row == __numberOfRows
		{
			return tableView.height
		}
		return 44.0
	}
}

// MARK: - UIGestureRecognizerDelegate
extension MenuView : UIGestureRecognizerDelegate
{
	func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool
	{
		if (self.tableView.panGestureRecognizer === otherGestureRecognizer)
		{
			return false
		}
		return true
	}
}
