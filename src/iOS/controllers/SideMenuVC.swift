// SideMenuVC.swift
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


protocol SideMenuVCDelegate
{
	func didSelectMenuItem(_ selectedVC: SelectedVC)
	func getSelectedController() -> SelectedVC
}

final class SideMenuVC : UIViewController
{
	// MARK: - Public properties
	// Table view
	@IBOutlet fileprivate var tableView: UITableView!
	// Menu delegate
	var menuDelegate: SideMenuVCDelegate?
	// MARK: - Private properties
	private let numberOfRows = 4

	override func viewDidLoad()
	{
		super.viewDidLoad()

		tableView.register(MenuViewTableViewCell.classForCoder(), forCellReuseIdentifier: "fr.whine.mpdremote.cell.menu")
		tableView.scrollsToTop = false
	}
}

// MARK: - UITableViewDataSource
extension SideMenuVC : UITableViewDataSource
{
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return numberOfRows + 1
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
			selected = menuDelegate?.getSelectedController() == .library
		case 1:
			cell.accessibilityLabel = NYXLocalizedString("lbl_section_server")
			image = #imageLiteral(resourceName: "img-server")
			selected = menuDelegate?.getSelectedController() == .server
		case 2:
			cell.accessibilityLabel = NYXLocalizedString("lbl_section_settings")
			image = #imageLiteral(resourceName: "img-settings")
			selected = menuDelegate?.getSelectedController() == .settings
		case 3:
			cell.accessibilityLabel = NYXLocalizedString("lbl_section_stats")
			image = #imageLiteral(resourceName: "img-stats")
			selected = menuDelegate?.getSelectedController() == .stats
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
extension SideMenuVC : UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		tableView.deselectRow(at: indexPath, animated: false)
		var selectedVC = SelectedVC.library
		switch (indexPath.row)
		{
		case 0:
			selectedVC = .library
		case 1:
			selectedVC = .server
		case 2:
			selectedVC = .settings
		case 3:
			selectedVC = .stats
		case numberOfRows:
			return
		default:
			break
		}

		/*if newTopViewController === APP_DELEGATE().homeVC
		{
			APP_DELEGATE().window?.bringSubview(toFront: MiniPlayerView.shared)
		}*/
		menuDelegate?.didSelectMenuItem(selectedVC)
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		if indexPath.row == numberOfRows
		{
			return tableView.height
		}
		return 64.0
	}
}
