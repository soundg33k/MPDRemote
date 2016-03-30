// ServerVC.swift
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


final class ServerVC : MenuVC
{
	// MARK: - Public properties
	private(set) var tableView: UITableView!
	// Server name
	private(set) var tfName: UITextField!
	// Server hostname
	private(set) var tfHostname: UITextField!
	// Server port
	private(set) var tfPort: UITextField!
	// Server password
	private(set) var tfPassword: UITextField!
	// Cover name
	private(set) var tfCoverName: UITextField!
	// Server url for cover
	private(set) var tfCoverURL: UITextField!
	// MPD Server
	private(set) var mpdServer: MPDServer?

	// MARK: - Private properties
	// Indicate that the keyboard is visible, flag
	private var _keyboardVisible = false

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()
		self.automaticallyAdjustsScrollViewInsets = false
		self.view.backgroundColor = UIColor.fromRGB(0xECECEC)

		// Customize navbar
		let headerColor = UIColor.whiteColor()
		let navigationBar = (self.navigationController?.navigationBar)!
		navigationBar.barTintColor = UIColor.fromRGB(kNYXAppColor)
		navigationBar.tintColor = headerColor
		navigationBar.translucent = false
		navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : headerColor]
		navigationBar.setBackgroundImage(UIImage(), forBarPosition:.Any, barMetrics:.Default)
		navigationBar.shadowImage = UIImage()
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem:.Save, target:self, action:#selector(ServerVC.validateSettingsAction(_:)))
		/*navigationBar.layer.shadowPath = UIBezierPath(rect:CGRect(-2.0, navigationBar.frame.height - 2.0, navigationBar.frame.width + 4.0, 4.0)).CGPath
		navigationBar.layer.shadowRadius = 3.0
		navigationBar.layer.shadowOpacity = 1.0
		navigationBar.layer.shadowColor = UIColor.blackColor().CGColor
		navigationBar.layer.masksToBounds = false*/

		// Navigation bar title
		let titleView = UILabel(frame:CGRect(0.0, 0.0, 100.0, 44.0))
		titleView.font = UIFont.systemFontOfSize(14.0)
		titleView.numberOfLines = 2
		titleView.textAlignment = .Center
		titleView.isAccessibilityElement = false
		titleView.textColor = self.navigationController?.navigationBar.tintColor
		titleView.text = NYXLocalizedString("lbl_header_server_cfg")
		self.navigationItem.titleView = titleView

		// TableView
		self.tableView = UITableView(frame:CGRect(0.0, 0.0, self.view.frame.width, self.view.frame.height - 64.0), style:.Grouped)
		self.tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier:"io.whine.mpdremote.cell.server")
		self.tableView.dataSource = self
		self.tableView.delegate = self
		self.tableView.rowHeight = 44.0
		self.view.addSubview(self.tableView)

		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(ServerVC.keyboardDidShowNotification(_:)), name:UIKeyboardDidShowNotification, object:nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(ServerVC.keyboardDidHideNotification(_:)), name:UIKeyboardDidHideNotification, object:nil)
	}

	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)

		if let serverAsData = NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefMPDServer)
		{
			if let server = NSKeyedUnarchiver.unarchiveObjectWithData(serverAsData) as! MPDServer?
			{
				self.mpdServer = server
			}
		}
		else
		{
			Logger.dlog("[+] No MPD server registered yet.")
		}

		self.tableView.reloadData()
	}

	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
	{
		return .Portrait
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle
	{
		return .LightContent
	}

	// MARK: - Buttons actions
	func validateSettingsAction(sender: AnyObject?)
	{
		self.view.endEditing(true)

		// Check server name (optional)
		var serverName = NYXLocalizedString("lbl_server_defaultname")
		if let strName = self.tfName.text
		{
			if strName.length > 0
			{
				serverName = strName
			}
		}

		// Check hostname / ip
		guard let ip = self.tfHostname.text where ip.length > 0 else
		{
			let alertController = UIAlertController(title:NYXLocalizedString("lbl_alert_servercfg_error"), message:NYXLocalizedString("lbl_alert_servercfg_error_host"), preferredStyle:.Alert)
			let cancelAction = UIAlertAction(title:NYXLocalizedString("lbl_ok"), style:.Cancel) { (action) in
			}
			alertController.addAction(cancelAction)
			self.presentViewController(alertController, animated:true, completion:nil)
			return
		}

		// Check port
		var port: UInt16 = 6600
		if let strPort = self.tfPort.text, p = UInt16(strPort)
		{
			port = p
		}

		// Check password (optional)
		var password = ""
		if let strPassword = self.tfPassword.text
		{
			if strPassword.length > 0
			{
				password = strPassword
			}
		}

		let server = password.length > 0 ? MPDServer(name:serverName, hostname:ip, port:port, password:password) : MPDServer(name:serverName, hostname:ip, port:port)
		let cnn = MPDConnection(server:server)
		if cnn.connect()
		{
			// Check web URL (optional)
			if let strURL = self.tfCoverURL.text
			{
				if strURL.length > 0
				{
					server.coverURL = strURL
				}
			}
			// Check cover name (optional)
			if let coverName = self.tfCoverName.text
			{
				if coverName.length > 0
				{
					server.coverName = coverName
				}
			}
			self.mpdServer = server
			let serverAsData = NSKeyedArchiver.archivedDataWithRootObject(server)
			NSUserDefaults.standardUserDefaults().setObject(serverAsData, forKey:kNYXPrefMPDServer)
			NSUserDefaults.standardUserDefaults().synchronize()
		}
		else
		{
			let alertController = UIAlertController(title:NYXLocalizedString("lbl_alert_servercfg_error"), message:NYXLocalizedString("lbl_alert_servercfg_error_msg"), preferredStyle:.Alert)
			let cancelAction = UIAlertAction(title:NYXLocalizedString("lbl_ok"), style:.Cancel) { (action) in
			}
			alertController.addAction(cancelAction)
			self.presentViewController(alertController, animated:true, completion:nil)
		}
		cnn.disconnect()
	}

	// MARK: - Notifications
	func keyboardDidShowNotification(aNotification: NSNotification)
	{
		if self._keyboardVisible
		{
			return
		}
		let info = aNotification.userInfo!
		let value = info[UIKeyboardFrameEndUserInfoKey]!
		let rawFrame = value.CGRectValue
		let keyboardFrame = self.view.convertRect(rawFrame, fromView:nil)
		self.tableView.frame = CGRect(self.tableView.frame.origin, self.tableView.frame.width, self.tableView.frame.height - keyboardFrame.height)
		self._keyboardVisible = true
	}

	func keyboardDidHideNotification(aNotification: NSNotification)
	{
		let info = aNotification.userInfo!
		let value = info[UIKeyboardFrameEndUserInfoKey]!
		let rawFrame = value.CGRectValue
		let keyboardFrame = self.view.convertRect(rawFrame, fromView:nil)
		self.tableView.frame = CGRect(self.tableView.frame.origin, self.tableView.frame.width, self.tableView.frame.height + keyboardFrame.height)
		self._keyboardVisible = false
	}
}

// MARK: - UITableViewDataSource
extension ServerVC : UITableViewDataSource
{
	func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
		return 2
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if section == 0
		{
			return 4
		}
		return 3
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let section = indexPath.section
		let row = indexPath.row
		let cell = tableView.dequeueReusableCellWithIdentifier("io.whine.mpdremote.cell.server", forIndexPath:indexPath)
		cell.selectionStyle = .None

		if section == 0
		{
			if row == 0
			{
				cell.textLabel?.text = NYXLocalizedString("lbl_server_name")
				if self.tfName == nil
				{
					self.tfName = UITextField(frame:CGRect(110.0, 0.0, self.view.frame.width - 120.0, cell.frame.height))
					self.tfName.backgroundColor = cell.backgroundColor
					self.tfName.placeholder = NYXLocalizedString("lbl_server_defaultname")
					self.tfName.keyboardType = .Default
					self.tfName.returnKeyType = .Continue
					self.tfName.autocorrectionType = .No
					self.tfName.autocapitalizationType = .None
					self.tfName.delegate = self
					cell.addSubview(self.tfName)
				}
				if let server = self.mpdServer
				{
					self.tfName.text = server.name
				}
			}
			else if row == 1
			{
				cell.textLabel?.text = NYXLocalizedString("lbl_server_host")
				if self.tfHostname == nil
				{
					self.tfHostname = UITextField(frame:CGRect(110.0, 0.0, self.view.frame.width - 120.0, cell.frame.height))
					self.tfHostname.backgroundColor = cell.backgroundColor
					self.tfHostname.placeholder = "127.0.0.1"
					self.tfHostname.keyboardType = .URL
					self.tfHostname.returnKeyType = .Continue
					self.tfHostname.autocorrectionType = .No
					self.tfHostname.autocapitalizationType = .None
					self.tfHostname.delegate = self
					cell.addSubview(self.tfHostname)
				}
				if let server = self.mpdServer
				{
					self.tfHostname.text = server.hostname
				}
			}
			else if row == 2
			{
				cell.textLabel?.text = NYXLocalizedString("lbl_server_port")
				if self.tfPort == nil
				{
					self.tfPort = UITextField(frame:CGRect(110.0, 0.0, self.view.frame.width - 120.0, cell.frame.height))
					self.tfPort.backgroundColor = cell.backgroundColor
					self.tfPort.placeholder = "6600"
					self.tfPort.keyboardType = .NumberPad
					self.tfPort.autocorrectionType = .No
					self.tfPort.delegate = self
					cell.addSubview(self.tfPort)
				}
				if let server = self.mpdServer
				{
					self.tfPort.text = String(server.port)
				}
			}
			else if row == 3
			{
				cell.textLabel?.text = NYXLocalizedString("lbl_server_password")
				if self.tfPassword == nil
				{
					self.tfPassword = UITextField(frame:CGRect(110.0, 0.0, self.view.frame.width - 120.0, cell.frame.height))
					self.tfPassword.backgroundColor = cell.backgroundColor
					self.tfPassword.placeholder = NYXLocalizedString("lbl_optional")
					self.tfPassword.keyboardType = .Default
					self.tfPassword.returnKeyType = .Done
					self.tfPassword.autocorrectionType = .No
					self.tfPassword.autocapitalizationType = .None
					self.tfPassword.delegate = self
					cell.addSubview(self.tfPassword)
				}
				if let server = self.mpdServer
				{
					self.tfPassword.text = server.password
				}
			}
		}
		else if section == 1
		{
			if row == 0
			{
				cell.textLabel?.text = NYXLocalizedString("lbl_server_coverurl")
				if self.tfCoverURL == nil
				{
					self.tfCoverURL = UITextField(frame:CGRect(140.0, 0.0, self.view.frame.width - 150.0, cell.frame.height))
					self.tfCoverURL.backgroundColor = cell.backgroundColor
					self.tfCoverURL.placeholder = "http://127.0.0.1:8080"
					self.tfCoverURL.keyboardType = .URL
					self.tfCoverURL.returnKeyType = .Continue
					self.tfCoverURL.autocorrectionType = .No
					self.tfCoverURL.autocapitalizationType = .None
					self.tfCoverURL.delegate = self
					cell.addSubview(self.tfCoverURL)
				}
				if let server = self.mpdServer
				{
					self.tfCoverURL.text = server.coverURL
				}
			}
			else if row == 1
			{
				cell.textLabel?.text = NYXLocalizedString("lbl_server_covername")
				if self.tfCoverName == nil
				{
					self.tfCoverName = UITextField(frame:CGRect(140.0, 0.0, self.view.frame.width - 150.0, cell.frame.height))
					self.tfCoverName.backgroundColor = cell.backgroundColor
					self.tfCoverName.text = "cover.jpg"
					self.tfCoverName.keyboardType = .Default
					self.tfCoverName.returnKeyType = .Done
					self.tfCoverName.autocorrectionType = .No
					self.tfCoverName.autocapitalizationType = .None
					self.tfCoverName.delegate = self
					cell.addSubview(self.tfCoverName)
				}
				if let server = self.mpdServer
				{
					self.tfCoverName.text = server.coverName
				}
			}
			else if row == 2
			{
				cell.selectionStyle = .Default
				cell.textLabel?.text = NYXLocalizedString("lbl_server_coverclearcache")
				cell.textLabel?.textAlignment = .Center
				cell.textLabel?.textColor = UIColor.redColor()
				cell.textLabel?.font = UIFont.boldSystemFontOfSize(15.0)
			}
		}

		return cell
	}

	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		return (section == 0) ? NYXLocalizedString("lbl_server_section_server") : NYXLocalizedString("lbl_server_section_cover")
	}
}

// MARK: - UITableViewDelegate
extension ServerVC : UITableViewDelegate
{
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		if indexPath.section == 1 && indexPath.row == 2
		{
			let fileManager = NSFileManager()
			let cachesDirectoryURL = fileManager.URLsForDirectory(.CachesDirectory, inDomains:.UserDomainMask).last!
			let coversDirectoryName = NSUserDefaults.standardUserDefaults().stringForKey(kNYXPrefDirectoryCovers)!
			let coversDirectoryURL = cachesDirectoryURL.URLByAppendingPathComponent(coversDirectoryName)

			do
			{
				try fileManager.removeItemAtURL(coversDirectoryURL)
				try fileManager.createDirectoryAtURL(coversDirectoryURL, withIntermediateDirectories:true, attributes:nil)
			}
			catch _
			{
				Logger.alog("[!] Can't delete cover cache :<")
			}
		}
		tableView.deselectRowAtIndexPath(indexPath, animated:true)
	}
}

// MARK: - UITextFieldDelegate
extension ServerVC : UITextFieldDelegate
{
	func textFieldShouldReturn(textField: UITextField) -> Bool
	{
		if textField === self.tfName
		{
			self.tfHostname.becomeFirstResponder()
		}
		else if textField === self.tfHostname
		{
			self.tfPort.becomeFirstResponder()
		}
		else if textField === self.tfPort
		{
			self.tfPassword.becomeFirstResponder()
		}
		else if textField === self.tfPassword
		{
			textField.resignFirstResponder()
		}
		else if textField === self.tfCoverURL
		{
			self.tfCoverName.resignFirstResponder()
		}
		else if textField === self.tfCoverName
		{
			textField.resignFirstResponder()
		}
		return true
	}
}
