// SettingsVC.swift
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


final class SettingsVC : MenuTVC
{
	// MARK: - Private properties
	// Night mode switch
	@IBOutlet private var swNightMode: UISwitch!
	// Night mode label
	@IBOutlet private var lblNightMode: UILabel!
	// Navigation title
	private var titleView: UILabel!

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Navigation bar title
		titleView = UILabel(frame: CGRect(0.0, 0.0, 100.0, 44.0))
		titleView.font = UIFont(name: "HelveticaNeue-Medium", size: 14.0)
		titleView.numberOfLines = 2
		titleView.textAlignment = .center
		titleView.isAccessibilityElement = false
		titleView.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		titleView.text = NYXLocalizedString("lbl_section_settings")
		navigationItem.titleView = titleView
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		self.nightModeSettingDidChange(nil)
		swNightMode.isOn = isNightModeEnabled()
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return .portrait
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return isNightModeEnabled() ? .lightContent : .default
	}

	// MARK: - IBActions
	@IBAction func toggleNightMode(_ sender: Any?)
	{
		UserDefaults.standard.set(!isNightModeEnabled(), forKey: kNYXPrefNightMode)
		UserDefaults.standard.synchronize()

		NotificationCenter.default.post(name: .nightModeSettingDidChange, object: nil)
	}

	// MARK: - Notifications
	override func nightModeSettingDidChange(_ aNotification: Notification?)
	{
		super.nightModeSettingDidChange(aNotification)

		if isNightModeEnabled()
		{
			navigationController?.navigationBar.barStyle = .black
			titleView.textColor = #colorLiteral(red: 0.7540688515, green: 0.7540867925, blue: 0.7540771365, alpha: 1)
			tableView.backgroundColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
			tableView.separatorColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
			tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.backgroundColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
		}
		else
		{
			navigationController?.navigationBar.barStyle = .default
			titleView.textColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
			tableView.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
			tableView.separatorColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
			tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		}
		lblNightMode.textColor = titleView.textColor

		setNeedsStatusBarAppearanceUpdate()
	}
}
