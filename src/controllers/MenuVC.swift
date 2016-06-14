// MenuVC.swift
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


private let MENU_WIDTH = CGFloat(230.0)
private let MENU_MIN_X = (-(MENU_WIDTH) - 2.0)
private var __startX = CGFloat(0.0)


class MenuVC : UIViewController
{
	// MARK: - Properties
	// Menu
	private(set) var menuView: MenuView! = nil
	// Screen edge gesture
	private var panGestureMenu: UIScreenEdgePanGestureRecognizer! = nil

	// MARK: - Initializers
	init()
	{
		super.init(nibName:nil, bundle:nil)

		// Hamburger button
		let image = UIImage(named:"btn-hamb")
		let b = UIBarButtonItem(image:image?.imageTintedWithColor(UIColor.whiteColor())?.imageWithRenderingMode(.AlwaysOriginal), style:.Plain, target:self, action:#selector(showLeftViewAction(_:)))
		b.accessibilityLabel = NYXLocalizedString("vo_displaymenu")
		self.navigationItem.leftBarButtonItem = b
	}

	required init?(coder aDecoder: NSCoder)
	{
		//fatalError("init(coder:) has not been implemented")
		super.init(coder:aDecoder)

		// Hamburger button
		let image = UIImage(named:"btn-hamb")
		let b = UIBarButtonItem(image:image?.imageTintedWithColor(UIColor.whiteColor())?.imageWithRenderingMode(.AlwaysOriginal), style:.Plain, target:self, action:#selector(showLeftViewAction(_:)))
		b.accessibilityLabel = NYXLocalizedString("vo_displaymenu")
		self.navigationItem.leftBarButtonItem = b
	}

	// MARK : UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		self.menuView = MenuView(frame:CGRect(MENU_MIN_X, 64.0, MENU_WIDTH, self.view.height - 64.0))
		self.menuView.menuDelegate = self
		self.menuView.visible = false
		self.navigationController!.view.addSubview(self.menuView)

		self.panGestureMenu = UIScreenEdgePanGestureRecognizer(target:self, action:#selector(panFromEdge(_:)))
		self.panGestureMenu.edges = .Left
		self.panGestureMenu.delegate = self
		self.view.addGestureRecognizer(self.panGestureMenu)
	}

	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
	{
		return .Portrait
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle
	{
		return .LightContent
	}

	// MARK : Button action
	func showLeftViewAction(sender: AnyObject?)
	{
		UIView.animateWithDuration(0.25, delay:0.0, options:.CurveEaseOut, animations:{
			let x = self.menuView.visible ? -(self.menuView.frame.width + 2.0) : 0.0
			self.menuView.frame = CGRect(x, self.menuView.frame.y, self.menuView.frame.size)
		}, completion:{ finished in
			let v = !self.menuView.visible
			self.menuView.visible = v
			self.navigationItem.leftBarButtonItem?.accessibilityLabel = NYXLocalizedString(v ? "vo_hidemenu" : "vo_displaymenu")
		})
	}

	// MARK: - Gesture
	func panFromEdge(gest: UIScreenEdgePanGestureRecognizer)
	{
		let view = gest.view
		switch (gest.state)
		{
			case .Began:
				__startX = self.menuView.frame.x
				break
			case .Changed:
				let translationX = gest.translationInView(view).x
				var tmp = __startX + translationX
				if (tmp > 0.0)
				{
					tmp = 0.0
				}
				else if (translationX < -self.menuView.frame.width)
				{
					tmp = -self.menuView.frame.width
				}
				self.menuView.frame.x = tmp
			case .Ended:
				let cmp = self.menuView.frame.x
				let limit = (MENU_MIN_X / 2.6)
				UIView.animateWithDuration(0.35, delay:0.0, options:.CurveEaseOut, animations:{
					self.menuView.frame.x = (cmp >= limit) ? 0.0 : MENU_MIN_X
				}, completion:{ finished in
					let v = (cmp >= limit)
					self.menuView.visible = v
					self.navigationItem.leftBarButtonItem?.accessibilityLabel = NYXLocalizedString(v ? "vo_hidemenu" : "vo_displaymenu")
				})
			default:
				break
		}
	}
}

// MARK: - MenuViewDelegate
extension MenuVC : MenuViewDelegate
{
	func menuViewShouldClose(menuView: UIView)
	{
		UIView.animateWithDuration(0.25, delay:0.0, options:.CurveEaseInOut, animations:{
			self.menuView.frame = CGRect(MENU_MIN_X, self.menuView.frame.y, menuView.frame.size)
		}, completion:{ finished in
			self.menuView.visible = false
			self.view.userInteractionEnabled = true
			self.navigationItem.leftBarButtonItem?.accessibilityLabel = NYXLocalizedString("vo_displaymenu")
		})
	}

	func menuViewDidClose(menuView: UIView)
	{
		self.view.userInteractionEnabled = true
		self.navigationItem.leftBarButtonItem?.accessibilityLabel = NYXLocalizedString("vo_displaymenu")
	}
}

// MARK: - UIGestureRecognizerDelegate
extension MenuVC : UIGestureRecognizerDelegate
{
	func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool
	{
		if (gestureRecognizer === self.panGestureMenu)
		{
			if (self.menuView.visible)
			{
				return false
			}
			return true
		}
		return true
	}
}
