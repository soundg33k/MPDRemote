// SettingsVC.swift
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
import MessageUI
import Compression


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
	// Fuzzy search label
	@IBOutlet private var lblFuzzySearch: UILabel!
	// Fuzzy search switch
	@IBOutlet private var swFuzzySearch: UISwitch!
	// Layout as table label
	@IBOutlet private var lblLayoutAsTable: UILabel!
	// Layout as table switch
	@IBOutlet private var swLayoutAsTable: UISwitch!
	// Send logs label
	@IBOutlet private var lblSendLogs: UILabel!
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
		titleView.textColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
		titleView.text = NYXLocalizedString("lbl_section_settings")
		navigationItem.titleView = titleView

		lblShake.text = NYXLocalizedString("lbl_pref_shaketoplayrandom")
		lblFuzzySearch.text = NYXLocalizedString("lbl_fuzzysearch")
		lblLayoutAsTable.text = NYXLocalizedString("lbl_pref_layoutastable")
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		swShake.isOn = UserDefaults.standard.bool(forKey: kNYXPrefShakeToPlayRandomAlbum)
		swFuzzySearch.isOn = UserDefaults.standard.bool(forKey: kNYXPrefFuzzySearch)
		swLayoutAsTable.isOn = UserDefaults.standard.bool(forKey: kNYXPrefCollectionViewLayoutTable)

		let version = applicationVersionAndBuild()
		lblVersion.text = "\(version.version) (\(version.build))"
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

	@IBAction func toggleFuzzySearch(_ sender: Any?)
	{
		let fuzzySearch = UserDefaults.standard.bool(forKey: kNYXPrefFuzzySearch)
		UserDefaults.standard.set(!fuzzySearch, forKey: kNYXPrefFuzzySearch)
		UserDefaults.standard.synchronize()
	}

	@IBAction func toggleTableLayout(_ sender: Any?)
	{
		let tableLayout = UserDefaults.standard.bool(forKey: kNYXPrefCollectionViewLayoutTable)
		UserDefaults.standard.set(!tableLayout, forKey: kNYXPrefCollectionViewLayoutTable)
		UserDefaults.standard.synchronize()
		NotificationCenter.default.post(name: .collectionViewsLayoutDidChange, object: nil)
	}

	// MARK: - Private
	fileprivate func applicationVersionAndBuild() -> (version: String, build: String)
	{
		let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
		let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as! String

		return (version, build)
	}

	fileprivate func sendLogs()
	{
		if MFMailComposeViewController.canSendMail()
		{
			guard let data = Logger.shared.export() else
			{
				let alertController = UIAlertController(title: NYXLocalizedString("lbl_error"), message:NYXLocalizedString("lbl_alert_logsexport_fail_msg"), preferredStyle: .alert)
				let okAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .destructive) { (action) in
				}
				alertController.addAction(okAction)
				present(alertController, animated: true, completion: nil)
				return
			}

			let mailComposerVC = MFMailComposeViewController()
			mailComposerVC.mailComposeDelegate = self
			mailComposerVC.setToRecipients(["contact.mpdremote@gmail.com"])
			mailComposerVC.setSubject("MPDRemote logs")
			if let compressed = data.compress(algorithm: COMPRESSION_ZLIB)
			{
				mailComposerVC.addAttachmentData(compressed, mimeType: "application/zip", fileName: "logs.zip")
			}
			else
			{
				mailComposerVC.addAttachmentData(data, mimeType: "text/plain" , fileName: "logs.txt")
			}


			var message = "MPDRemote \(applicationVersionAndBuild().version) (\(applicationVersionAndBuild().build))\niOS \(UIDevice.current.systemVersion)\n\n"
			if let mpdServerAsData = UserDefaults.standard.data(forKey: kNYXPrefMPDServer)
			{
				if let server = NSKeyedUnarchiver.unarchiveObject(with: mpdServerAsData) as! AudioServer?
				{
					message += "MPD server:\n\(server.publicDescription())\n\n"
				}
			}

			if let webServerAsData = UserDefaults.standard.data(forKey: kNYXPrefWEBServer)
			{
				if let server = NSKeyedUnarchiver.unarchiveObject(with: webServerAsData) as! CoverWebServer?
				{
					message += "Cover server:\n\(server.publicDescription())\n\n"
				}
			}
			mailComposerVC.setMessageBody(message, isHTML: false)

			present(mailComposerVC, animated: true, completion: nil)

		}
		else
		{
			let alertController = UIAlertController(title: NYXLocalizedString("lbl_error"), message:NYXLocalizedString("lbl_alert_nomailaccount_msg"), preferredStyle: .alert)
			let okAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .destructive) { (action) in
			}
			alertController.addAction(okAction)
			present(alertController, animated: true, completion: nil)
		}
	}
}

// MARK: - UITableViewDelegate
extension SettingsVC
{
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		if indexPath.section == 3 && indexPath.row == 0
		{
			sendLogs()
		}

		tableView.deselectRow(at: indexPath, animated: true)
	}

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
				label.text = NYXLocalizedString("lbl_ui").uppercased()
			case 1:
				label.text = NYXLocalizedString("lbl_behaviour").uppercased()
			case 2:
				label.text = NYXLocalizedString("lbl_search").uppercased()
			case 3:
				label.text = NYXLocalizedString("lbl_troubleshoot").uppercased()
			case 4:
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

extension SettingsVC : MFMailComposeViewControllerDelegate
{
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
	{
		controller.dismiss(animated: true, completion: nil)
	}
}
