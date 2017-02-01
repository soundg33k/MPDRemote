// MenuTVC.swift
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


private let MENU_WIDTH = CGFloat(230.0)
private let MENU_MIN_X = (-(MENU_WIDTH) - 2.0)
private var __startX = CGFloat(0.0)


class MenuTVC : UITableViewController
{
	// MARK: - Public properties
	// Menu
	private(set) var menuView: MenuView! = nil
	// Screen edge gesture
	private(set) var panGestureMenu: UIScreenEdgePanGestureRecognizer! = nil

	// MARK: - Initializers
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)

		// Hamburger button
		let b = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-hamb").withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(showLeftViewAction(_:)))
		b.tintColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
		b.accessibilityLabel = NYXLocalizedString("vo_displaymenu")
		self.navigationItem.leftBarButtonItem = b
	}

	// MARK : UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		menuView = MenuView(frame: CGRect(MENU_MIN_X, 64.0, MENU_WIDTH, view.height - 64.0))
		menuView.menuDelegate = self
		menuView.visible = false
		navigationController!.view.addSubview(menuView)

		panGestureMenu = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(panFromEdge(_:)))
		panGestureMenu.edges = .left
		panGestureMenu.delegate = self
		view.addGestureRecognizer(panGestureMenu)
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return .portrait
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .default
	}

	// MARK : Button action
	func showLeftViewAction(_ sender: Any?)
	{
		UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
			let x = self.menuView.visible ? -(self.menuView.frame.width + 2.0) : 0.0
			self.menuView.frame = CGRect(x, self.menuView.frame.y, self.menuView.frame.size)
			self.view.alpha = self.menuView.visible ? 1.0 : 0.4
		}, completion:{ finished in
			let v = !self.menuView.visible
			self.menuView.visible = v
			self.navigationItem.leftBarButtonItem?.accessibilityLabel = NYXLocalizedString(v ? "vo_hidemenu" : "vo_displaymenu")
		})
	}

	// MARK: - Gesture
	func panFromEdge(_ gest: UIScreenEdgePanGestureRecognizer)
	{
		let view = gest.view
		switch (gest.state)
		{
			case .began:
				__startX = menuView.frame.x
				break
			case .changed:
				let translationX = gest.translation(in: view).x
				var tmp = __startX + translationX
				if (tmp > 0.0)
				{
					tmp = 0.0
				}
				else if (translationX < -menuView.frame.width)
				{
					tmp = -menuView.frame.width
				}
				menuView.frame.x = tmp
				self.view.alpha = __minBackgroundOpacity + fabs(tmp / (menuView.frame.width + 2.0))
			case .ended:
				let cmp = menuView.frame.x
				let limit = (MENU_MIN_X / 2.6)
				let visible = (cmp >= limit)
				UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveEaseOut, animations: {
					self.menuView.frame.x = visible ? 0.0 : MENU_MIN_X
					self.view.alpha = visible ? __minBackgroundOpacity : 1.0
				}, completion:{ finished in
					self.menuView.visible = visible
					self.navigationItem.leftBarButtonItem?.accessibilityLabel = NYXLocalizedString(visible ? "vo_hidemenu" : "vo_displaymenu")
				})
			default:
				break
		}
	}
}

// MARK: - MenuViewDelegate
extension MenuTVC : MenuViewDelegate
{
	func menuViewShouldClose(_ menuView: UIView)
	{
		UIView.animate(withDuration: 0.25, delay: 0.0, options: UIViewAnimationOptions(), animations: {
			self.menuView.frame = CGRect(MENU_MIN_X, self.menuView.frame.y, menuView.frame.size)
			self.view.alpha = 1.0
		}, completion:{ finished in
			self.menuView.visible = false
			self.view.isUserInteractionEnabled = true
			self.navigationItem.leftBarButtonItem?.accessibilityLabel = NYXLocalizedString("vo_displaymenu")
		})
	}

	func menuViewDidClose(_ menuView: UIView)
	{
		view.isUserInteractionEnabled = true
		navigationItem.leftBarButtonItem?.accessibilityLabel = NYXLocalizedString("vo_displaymenu")
	}

	func menuViewDidMove(_ menuView: UIView)
	{
		self.view.alpha = __minBackgroundOpacity + fabs(menuView.x / (menuView.frame.width + 2.0))
	}
}

// MARK: - UIGestureRecognizerDelegate
extension MenuTVC : UIGestureRecognizerDelegate
{
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool
	{
		if (gestureRecognizer === self.panGestureMenu)
		{
			return !menuView.visible
		}
		return true
	}
}
