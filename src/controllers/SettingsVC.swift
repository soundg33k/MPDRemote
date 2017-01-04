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


private let headerSectionHeight: CGFloat = 32.0


final class SettingsVC : MenuTVC
{
	// MARK: - Private properties
	// Version label
	@IBOutlet private var lblVersion: UILabel!
	// Shake to play label
	@IBOutlet private var lblShake: UILabel!
	// Shake to play switch
	@IBOutlet private var swShake: UISwitch!
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

		lblShake.text = NYXLocalizedString("lbl_pref_shaketoplayrandom")
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		swShake.isOn = UserDefaults.standard.bool(forKey: kNYXPrefShakeToPlayRandomAlbum)

		let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
		let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as! String
		lblVersion.text = "\(version) (\(build))"
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return .portrait
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .default
	}

	// MARK: - IBActions
	@IBAction func toggleShakeToPlay(_ sender: Any?)
	{
		let shake = UserDefaults.standard.bool(forKey: kNYXPrefShakeToPlayRandomAlbum)
		UserDefaults.standard.set(!shake, forKey: kNYXPrefShakeToPlayRandomAlbum)
		UserDefaults.standard.synchronize()
	}
}

// MARK: - UITableViewDelegate
extension SettingsVC
{
	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
	{
		let dummy = UIView(frame: CGRect(0.0, 0.0, tableView.width, headerSectionHeight))
		dummy.backgroundColor = tableView.backgroundColor

		let label = UILabel(frame: CGRect(10.0, 0.0, dummy.width - 20.0, dummy.height))
		label.backgroundColor = dummy.backgroundColor
		label.textColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
		label.font = UIFont.systemFont(ofSize: 15.0)
		dummy.addSubview(label)

		switch section
		{
			case 0:
				label.text = NYXLocalizedString("lbl_behaviour").uppercased()
			case 1:
				label.text = NYXLocalizedString("lbl_version").uppercased()
			default:
				break
		}

		return dummy
	}

	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
	{
		return headerSectionHeight
	}
}
