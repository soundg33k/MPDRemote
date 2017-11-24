// ServerTV_VC.swift
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


let headerSectionHeight = CGFloat(32)


final class ServerTV_VC : UIViewController
{
	// MARK: - Private properties
	// MPD conf tablebiew
	@IBOutlet fileprivate var viewMPD: UIView!
	// WEB conf tablebiew
	@IBOutlet fileprivate var viewWEB: UIView!
	// MPD Server name
	@IBOutlet fileprivate var tfMPDName: UITextField!
	// MPD Server hostname
	@IBOutlet fileprivate var tfMPDHostname: UITextField!
	// MPD Server port
	@IBOutlet fileprivate var tfMPDPort: UITextField!
	// MPD Server password
	@IBOutlet fileprivate var tfMPDPassword: UITextField!
	// MPD Output
	@IBOutlet fileprivate var tfMPDOutput: UITextField!
	// WEB Server hostname
	@IBOutlet fileprivate var tfWEBHostname: UITextField!
	// WEB Server port
	@IBOutlet fileprivate var tfWEBPort: UITextField!
	// Cover name
	@IBOutlet fileprivate var tfWEBCoverName: UITextField!
	// Cell Labels
	@IBOutlet private var lblMPDName: UILabel! = nil
	@IBOutlet private var lblMPDHostname: UILabel! = nil
	@IBOutlet private var lblMPDPort: UILabel! = nil
	@IBOutlet private var lblMPDPassword: UILabel! = nil
	@IBOutlet private var lblMPDOutput: UILabel! = nil
	@IBOutlet private var lblWEBHostname: UILabel! = nil
	@IBOutlet private var lblWEBPort: UILabel! = nil
	@IBOutlet private var lblWEBCoverName: UILabel! = nil
	@IBOutlet private var lblClearCache: UILabel! = nil
	// MPD Server
	private var mpdServer: AudioServer?
	// WEB Server for covers
	private var webServer: CoverWebServer?
	// Indicate that the keyboard is visible, flag
	private var _keyboardVisible = false

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		lblMPDName.text = NYXLocalizedString("lbl_server_name")
		lblMPDHostname.text = NYXLocalizedString("lbl_server_host")
		lblMPDPort.text = NYXLocalizedString("lbl_server_port")
		lblMPDPassword.text = NYXLocalizedString("lbl_server_password")
		lblMPDOutput.text = NYXLocalizedString("lbl_server_output")
		lblWEBHostname.text = NYXLocalizedString("lbl_server_coverurl")
		lblWEBPort.text = NYXLocalizedString("lbl_server_port")
		lblWEBCoverName.text = NYXLocalizedString("lbl_server_covername")
		//lblrCache.text = NYXLocalizedString("lbl_server_coverclearcache")
		tfMPDName.placeholder = NYXLocalizedString("lbl_server_defaultname")

		// Keyboard appearance notifications
		//NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShowNotification(_:)), name: .UIKeyboardDidShow, object: nil)
		//NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHideNotification(_:)), name: .UIKeyboardDidHide, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(audioOutputConfigurationDidChangeNotification(_:)), name: .audioOutputConfigurationDidChange, object: nil)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		let decoder = JSONDecoder()

		if let mpdServerAsData = Settings.shared.data(forKey: kNYXPrefMPDServer)
		{
			do
			{
				let server = try decoder.decode(AudioServer.self, from: mpdServerAsData)
				mpdServer = server
			}
			catch let error
			{
				Logger.shared.log(type: .debug, message: "Failed to decode mpd server: \(error.localizedDescription)")
			}
		}
		else
		{
			Logger.shared.log(type: .debug, message: "No audio server registered yet")
		}

		if let webServerAsData = Settings.shared.data(forKey: kNYXPrefWEBServer)
		{
			do
			{
				let server = try decoder.decode(CoverWebServer.self, from: webServerAsData)
				webServer = server
			}
			catch let error
			{
				Logger.shared.log(type: .debug, message: "Failed to decode web server: \(error.localizedDescription)")
			}
		}
		else
		{
			Logger.shared.log(type: .debug, message: "No web server registered yet")
		}

		updateFields()
	}

	// MARK: - Buttons actions
	@IBAction func validateSettingsAction(_ sender: Any?)
	{
		view.endEditing(true)

		// Check MPD server name (optional)
		var serverName = NYXLocalizedString("lbl_server_defaultname")
		if let strName = tfMPDName.text , strName.count > 0
		{
			serverName = strName
		}

		// Check MPD hostname / ip
		guard let ip = tfMPDHostname.text , ip.count > 0 else
		{
			let alertController = UIAlertController(title: NYXLocalizedString("lbl_alert_servercfg_error"), message:NYXLocalizedString("lbl_alert_servercfg_error_host"), preferredStyle: .alert)
			let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel) { (action) in
			}
			alertController.addAction(cancelAction)
			present(alertController, animated: true, completion: nil)
			return
		}

		// Check MPD port
		var port = UInt16(6600)
		if let strPort = tfMPDPort.text, let p = UInt16(strPort)
		{
			port = p
		}

		// Check MPD password (optional)
		var password = ""
		if let strPassword = tfMPDPassword.text , strPassword.count > 0
		{
			password = strPassword
		}

		let encoder = JSONEncoder()
		let mpdServer = AudioServer(name: serverName, hostname: ip, port: port, password: password)
		let cnn = MPDConnection(mpdServer)
		if cnn.connect().succeeded
		{
			self.mpdServer = mpdServer
			do
			{
				let serverAsData = try encoder.encode(mpdServer)
				Settings.shared.set(serverAsData, forKey: kNYXPrefMPDServer)
			}
			catch let error
			{
				Logger.shared.log(error: error)
			}

			NotificationCenter.default.post(name: .audioServerConfigurationDidChange, object: mpdServer)

			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
				self.updateOutputsLabel()
			})
		}
		else
		{
			Settings.shared.removeObject(forKey: kNYXPrefMPDServer)
			let alertController = UIAlertController(title: NYXLocalizedString("lbl_alert_servercfg_error"), message:NYXLocalizedString("lbl_alert_servercfg_error_msg"), preferredStyle: .alert)
			let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel) { (action) in
			}
			alertController.addAction(cancelAction)
			present(alertController, animated: true, completion: nil)
		}
		cnn.disconnect()

		// Check web URL (optional)
		if let strURL = tfWEBHostname.text , String.isNullOrWhiteSpace(strURL) == false
		{
			var port = UInt16(80)
			if let strPort = tfWEBPort.text, let p = UInt16(strPort)
			{
				port = p
			}

			var coverName = "cover.jpg"
			if let cn = tfWEBCoverName.text , String.isNullOrWhiteSpace(cn) == false
			{
				if String.isNullOrWhiteSpace(URL(fileURLWithPath: cn).pathExtension) == false
				{
					coverName = cn
				}
			}
			let webServer = CoverWebServer(name: "CoverServer", hostname: strURL, port: port, coverName: coverName)
			self.webServer = webServer

			do
			{
				let serverAsData = try encoder.encode(webServer)
				Settings.shared.set(serverAsData, forKey: kNYXPrefWEBServer)
			}
			catch let error
			{
				Logger.shared.log(error: error)
			}
		}
		else
		{
			Settings.shared.removeObject(forKey: kNYXPrefWEBServer)
		}

		Settings.shared.synchronize()
	}

	@IBAction func browserZeroConfServers(_ sender: Any?)
	{
		/*let sb = UIStoryboard(name: "main", bundle: nil)
		let nvc = sb.instantiateViewController(withIdentifier: "ZeroConfBrowserNVC") as! NYXNavigationController
		let vc = nvc.topViewController as! ZeroConfBrowserTVC
		vc.delegate = self
		self.navigationController?.present(nvc, animated: true, completion: nil)*/
	}

	// MARK: - Notifications
	/*@objc func keyboardDidShowNotification(_ aNotification: Notification)
	{
		if _keyboardVisible
		{
			return
		}

		guard let info = aNotification.userInfo else
		{
			return
		}

		guard let value = info[UIKeyboardFrameEndUserInfoKey] as! NSValue? else
		{
			return
		}

		let keyboardFrame = view.convert(value.cgRectValue, from: nil)
		tableView.frame = CGRect(tableView.frame.origin, tableView.frame.width, tableView.frame.height - keyboardFrame.height)
		_keyboardVisible = true
	}

	@objc func keyboardDidHideNotification(_ aNotification: Notification)
	{
		if _keyboardVisible == false
		{
			return
		}

		guard let info = aNotification.userInfo else
		{
			return
		}

		guard let value = info[UIKeyboardFrameEndUserInfoKey] as! NSValue? else
		{
			return
		}

		let keyboardFrame = view.convert(value.cgRectValue, from: nil)
		tableView.frame = CGRect(tableView.frame.origin, tableView.frame.width, tableView.frame.height + keyboardFrame.height)
		_keyboardVisible = false
	}*/

	@objc func audioOutputConfigurationDidChangeNotification(_ aNotification: Notification)
	{
		updateOutputsLabel()
	}

	// MARK: - Private
	fileprivate func updateFields()
	{
		if let server = mpdServer
		{
			tfMPDName.text = server.name
			tfMPDHostname.text = server.hostname
			tfMPDPort.text = String(server.port)
			tfMPDPassword.text = server.password
			updateOutputsLabel()
		}
		else
		{
			tfMPDName.text = ""
			tfMPDHostname.text = ""
			tfMPDPort.text = "6600"
			tfMPDPassword.text = ""
			tfMPDOutput.text = ""
		}

		/*if let server = webServer
		{
			tfWEBHostname.text = server.hostname
			tfWEBPort.text = String(server.port)
			tfWEBCoverName.text = server.coverName
		}
		else
		{
			tfWEBHostname.text = ""
			tfWEBPort.text = "80"
			tfWEBCoverName.text = "cover.jpg"
		}

		updateCacheLabel()*/
	}

	fileprivate func clearCache(confirm: Bool)
	{
		let clearBlock = { () -> Void in
			let cachesDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last!
			let coversDirectoryName = Settings.shared.string(forKey: kNYXPrefCoversDirectory)!
			let coversDirectoryURL = cachesDirectoryURL.appendingPathComponent(coversDirectoryName)

			do
			{
				try FileManager.default.removeItem(at: coversDirectoryURL)
				try FileManager.default.createDirectory(at: coversDirectoryURL, withIntermediateDirectories: true, attributes: nil)
				URLCache.shared.removeAllCachedResponses()
			}
			catch _
			{
				Logger.shared.log(type: .error, message: "Can't delete cover cache")
			}
			self.updateCacheLabel()
		}

		if confirm
		{
			let alertController = UIAlertController(title: NYXLocalizedString("lbl_alert_purge_cache_title"), message:NYXLocalizedString("lbl_alert_purge_cache_msg"), preferredStyle: .alert)
			let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel) { (action) in
			}
			alertController.addAction(cancelAction)
			let okAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .destructive) { (action) in
				clearBlock()
			}
			alertController.addAction(okAction)
			present(alertController, animated: true, completion: nil)
		}
		else
		{
			clearBlock()
		}
	}

	fileprivate func updateCacheLabel()
	{
		guard let cachesDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last else {return}
		DispatchQueue.global().async {
			let size = FileManager.default.sizeOfDirectoryAtURL(cachesDirectoryURL)
			DispatchQueue.main.async {
				self.lblClearCache.text = "\(NYXLocalizedString("lbl_server_coverclearcache")) (\(String(format: "%.2f", Double(size) / 1048576.0))\(NYXLocalizedString("lbl_megabytes")))"
			}
		}
	}

	fileprivate func updateOutputsLabel()
	{
		PlayerController.shared.getAvailableOutputs {
			DispatchQueue.main.async {
				let outputs = PlayerController.shared.outputs
				if outputs.count == 0
				{
					self.lblMPDOutput.text = NYXLocalizedString("lbl_server_no_output_available")
					return
				}
				let enabledOutputs = outputs.filter({$0.enabled})
				if enabledOutputs.count == 0
				{
					self.lblMPDOutput.text = NYXLocalizedString("lbl_server_no_output_enabled")
					return
				}
				let text = enabledOutputs.reduce("", {$0 + $1.name + ", "})
				let x = text[..<text.index(text.endIndex, offsetBy: -2)]
				self.lblMPDOutput.text = String(x)
				//self.lblMPDOutput.text = text.substring(to: text.index(text.endIndex, offsetBy: -2))
			}
		}
	}
}

// MARK: - UITableViewDataSource
/*extension ServerTV_VC : UITableViewDataSource
{
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return 4
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		if tableView == tvMPD
		{
			let cell = tableView.dequeueReusableCell(withIdentifier: "fr.whine.mpdremote.cell.server.mpd", for: indexPath)
			switch indexPath.row
			{
				case 0:
					if tfMPDName == nil
					{
						tfMPDName = UITextField(frame: CGRect(cell.width - 200, 0, 200, cell.height))
						tfMPDName.textAlignment = .right
						tfMPDName.text = "MUSIQUALITY"
						cell.contentView.addSubview(tfMPDName)
					}
					cell.textLabel?.text = NYXLocalizedString("lbl_server_name")
					let x = (cell.textLabel?.right)! + 10.0
					tfMPDName.frame = CGRect(x, 0, cell.contentView.width - x, cell.contentView.height)

			case 1:
				cell.textLabel?.text = NYXLocalizedString("lbl_server_host")
			case 2:
				cell.textLabel?.text = NYXLocalizedString("lbl_server_port")
			case 3:
				cell.textLabel?.text = NYXLocalizedString("lbl_server_password")
			case 4:
				cell.textLabel?.text = NYXLocalizedString("lbl_server_output")
				default:
					break
			}
			return cell
		}
		else
		{
			let cell = tableView.dequeueReusableCell(withIdentifier: "fr.whine.mpdremote.cell.server.web", for: indexPath)
			switch indexPath.row
			{
			case 0:
				cell.textLabel?.text = NYXLocalizedString("lbl_server_coverurl")
			case 1:
				cell.textLabel?.text = NYXLocalizedString("lbl_server_port")
			case 2:
				cell.textLabel?.text = NYXLocalizedString("lbl_server_covername")
			case 3:
				cell.textLabel?.text = NYXLocalizedString("lbl_server_coverclearcache")
			default:
				break
			}
			return cell
		}
	}
}

// MARK: - UITableViewDelegate
extension ServerTV_VC : UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		if indexPath.section == 0 && indexPath.row == 4
		{
			/*guard let cell = tableView.cellForRow(at: indexPath) else
			{
				return
			}

			let vc = AudioOutputsTVC()
			vc.modalPresentationStyle = .popover
			if let popController = vc.popoverPresentationController
			{
				popController.permittedArrowDirections = .up
				popController.sourceRect = cell.bounds
				popController.sourceView = cell
				popController.delegate = self
				self.present(vc, animated: true, completion: {
				});
			}*/
		}
		else if indexPath.section == 1 && indexPath.row == 3
		{
			clearCache(confirm: true)
		}
	}

	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		if tableView === tvMPD
		{
			return NYXLocalizedString("lbl_server_section_server").uppercased()
		}
		else
		{
			return NYXLocalizedString("lbl_server_section_cover").uppercased()
		}
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
	{
		return headerSectionHeight
	}
}*/


// MARK: - UITextFieldDelegate
extension ServerTV_VC : UITextFieldDelegate
{
	func textFieldShouldReturn(_ textField: UITextField) -> Bool
	{
		if textField === tfMPDName
		{
			tfMPDHostname.becomeFirstResponder()
		}
		else if textField === tfMPDHostname
		{
			tfMPDPort.becomeFirstResponder()
		}
		else if textField === tfMPDPort
		{
			tfMPDPassword.becomeFirstResponder()
		}
		else if textField === tfMPDPassword
		{
			textField.resignFirstResponder()
		}
		else if textField === tfWEBHostname
		{
			tfWEBPort.becomeFirstResponder()
		}
		else if textField === tfWEBPort
		{
			tfWEBCoverName.becomeFirstResponder()
		}
		else
		{
			textField.resignFirstResponder()
		}
		return true
	}
}
