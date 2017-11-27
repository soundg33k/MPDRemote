// ContainerVC.swift
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
import QuartzCore


protocol ContainerVCDelegate
{
	func toggleMenu()
	func isMenuVisible() -> Bool
	func showServerVC()
}

protocol CenterViewController
{
	var containerDelegate: ContainerVCDelegate? {get set}
}

enum SelectedVC
{
	case library
	case settings
	case server
	case stats
}

final class ContainerVC : UIViewController
{
	// MARK: - Private properties
	// Main VC
	private var centerViewController: NYXNavigationController! = nil
	// Menu VC
	private var leftViewController: SideMenuVC? = nil
	// Offset
	private let expandedOffset: CGFloat = 120.0
	// Current display state
	private var menuVisible = false
	{
		didSet
		{
			toggleShadow(menuVisible)
		}
	}
	// Current displayed VC
	private var selectedVC = SelectedVC.library
	// Pan gesture
	private var panGestureRecognizer: UIPanGestureRecognizer! = nil

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))

		_updateCenterVC()
	}

	// MARK: - Private
	private func _updateCenterVC()
	{
		// Remove current VC
		if let currentCenterVC = centerViewController
		{
			if let v = currentCenterVC.view
			{
				v.removeGestureRecognizer(panGestureRecognizer)
			}
			currentCenterVC.remove()
		}

		// Instantiate new VC
		let newVC: NYXNavigationController!
		switch self.selectedVC
		{
			case .library:
				newVC = UIStoryboard.libraryVC()
			case .server:
				newVC = UIStoryboard.serverTVC()
			case .settings:
				newVC = UIStoryboard.settingsTVC()
			case .stats:
				newVC = UIStoryboard.statsTVC()
		}

		// Add the new VC
		centerViewController = newVC
		self.add(centerViewController)

		var vc = centerViewController.topViewController as! CenterViewController
		vc.containerDelegate = self

		centerViewController.view.addGestureRecognizer(panGestureRecognizer)
	}

	private func addMenuViewController()
	{
		guard leftViewController == nil else { return }

		if let vc = UIStoryboard.leftViewController()
		{
			vc.menuDelegate = self
			view.insertSubview(vc.view, at: 0)

			addChildViewController(vc)
			vc.didMove(toParentViewController: self)

			leftViewController = vc
		}
	}

	private func showMenu(expand: Bool)
	{
		if expand
		{
			self.menuVisible = true
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
				self.centerViewController.view.frame.origin.x = self.centerViewController.view.frame.width - self.expandedOffset
			}, completion: { finished in
			})
		}
		else
		{
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
				self.centerViewController.view.frame.origin.x = 0.0
			}, completion: { finished in
				self.menuVisible = false
				self.leftViewController?.view.removeFromSuperview()
				self.leftViewController = nil
			})
		}
	}

	private func toggleShadow(_ showShadow: Bool)
	{
		centerViewController.view.layer.shadowOpacity = showShadow ? 0.8 : 0.0
	}
}

// MARK: - ContainerVCDelegate
extension ContainerVC : ContainerVCDelegate
{
	func toggleMenu()
	{
		if menuVisible == false
		{
			addMenuViewController()
		}

		showMenu(expand: menuVisible == false)
	}

	func isMenuVisible() -> Bool
	{
		return menuVisible
	}

	func showServerVC()
	{
		if self.selectedVC != .server
		{
			self.selectedVC = .server
			_updateCenterVC()
			if menuVisible
			{
				self.toggleMenu()
			}
		}
	}
}

// MARK: - SideMenuVCDelegate
extension ContainerVC : SideMenuVCDelegate
{
	func didSelectMenuItem(_ selectedVC: SelectedVC)
	{
		if self.selectedVC != selectedVC
		{
			self.selectedVC = selectedVC
			_updateCenterVC()
			self.toggleMenu()
		}
	}

	func getSelectedController() -> SelectedVC
	{
		return self.selectedVC
	}
}

// MARK: - UIGestureRecognizerDelegate
extension ContainerVC : UIGestureRecognizerDelegate
{
	@objc func pan(_ recognizer: UIPanGestureRecognizer)
	{
		let leftToRight = (recognizer.velocity(in: view).x > 0)

		switch recognizer.state
		{
			case .began:
				if menuVisible == false
				{
					if leftToRight
					{
						addMenuViewController()
					}
					else
					{
						recognizer.isEnabled = false
					}
					toggleShadow(true)
				}
			case .changed:
				if let rview = recognizer.view
				{
					rview.center.x = rview.center.x + recognizer.translation(in: view).x
					recognizer.setTranslation(.zero, in: view)
				}
			case .ended:
				if let _ = leftViewController, let rview = recognizer.view
				{
					let hasMovedGreaterThanHalfway = rview.center.x > view.bounds.size.width
					showMenu(expand: hasMovedGreaterThanHalfway)
				}
				recognizer.isEnabled = true
			case .cancelled:
				recognizer.isEnabled = true
			default:
				break
		}
	}
}

private extension UIStoryboard
{
	static func main() -> UIStoryboard
	{
		return UIStoryboard(name: "main-iphone", bundle: .main)
	}

	static func leftViewController() -> SideMenuVC?
	{
		return main().instantiateViewController(withIdentifier: "SideMenuVC") as? SideMenuVC
	}

	static func libraryVC() -> NYXNavigationController?
	{
		return main().instantiateViewController(withIdentifier: "RootNVC") as? NYXNavigationController
	}

	static func serverTVC() -> NYXNavigationController?
	{
		return main().instantiateViewController(withIdentifier: "ServerNVC") as? NYXNavigationController
	}

	static func statsTVC() -> NYXNavigationController?
	{
		return main().instantiateViewController(withIdentifier: "StatsNVC") as? NYXNavigationController
	}

	static func settingsTVC() -> NYXNavigationController?
	{
		return main().instantiateViewController(withIdentifier: "SettingsNVC") as? NYXNavigationController
	}
}
