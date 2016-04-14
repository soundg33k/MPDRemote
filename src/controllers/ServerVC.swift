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
import MultipeerConnectivity


final class ServerVC : MenuVC
{
	// MARK: - Private properties
	// Tableview
	private var tableView: UITableView!
	// MPD Server name
	private var tfMPDName: UITextField!
	// MPD Server hostname
	private var tfMPDHostname: UITextField!
	// MPD Server port
	private var tfMPDPort: UITextField!
	// MPD Server password
	private var tfMPDPassword: UITextField!
	// WEB Server hostname
	private var tfWEBHostname: UITextField!
	// WEB Server port
	private var tfWEBPort: UITextField!
	// Cover name
	private var tfWEBCoverName: UITextField!
	// MPD Server
	private var mpdServer: MPDServer?
	// WEB Server for covers
	private var webServer: WEBServer?
	// Indicate that the keyboard is visible, flag
	private var _keyboardVisible = false
	// Bonjour
	//private var serviceBrowser: MCNearbyServiceBrowser!

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
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem:.Save, target:self, action:#selector(validateSettingsAction(_:)))

		// Navigation bar title
		let titleView = UILabel(frame:CGRect(0.0, 0.0, 100.0, 44.0))
		titleView.font = UIFont(name:"HelveticaNeue-Medium", size:14.0)
		titleView.numberOfLines = 2
		titleView.textAlignment = .Center
		titleView.isAccessibilityElement = false
		titleView.textColor = self.navigationController?.navigationBar.tintColor
		titleView.text = NYXLocalizedString("lbl_header_server_cfg")
		self.navigationItem.titleView = titleView

		// TableView
		self.tableView = UITableView(frame:CGRect(0.0, 0.0, self.view.width, self.view.height - 64.0), style:.Grouped)
		self.tableView.dataSource = self
		self.tableView.delegate = self
		self.tableView.rowHeight = 44.0
		self.view.addSubview(self.tableView)

		// Keyboard appearance notifications
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(keyboardDidShowNotification(_:)), name:UIKeyboardDidShowNotification, object:nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(keyboardDidHideNotification(_:)), name:UIKeyboardDidHideNotification, object:nil)
	}

	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)

		/*let myPeerId = MCPeerID(displayName:"MPDRemote browser")
		self.serviceBrowser = MCNearbyServiceBrowser(peer:myPeerId, serviceType:"mpd")
		self.serviceBrowser.delegate = self
		self.serviceBrowser.startBrowsingForPeers()*/
		/*let session = MCSession(peer:myPeerId, securityIdentity:nil, encryptionPreference:.None)
		session.delegate = self
		let browserViewController = MCBrowserViewController(browser:self.serviceBrowser, session:session)
		browserViewController.delegate = self
		self.presentViewController(browserViewController, animated:true, completion: {
			Logger.dlog("???")
			self.serviceBrowser.startBrowsingForPeers()
		})*/

		if let mpdServerAsData = NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefMPDServer)
		{
			if let server = NSKeyedUnarchiver.unarchiveObjectWithData(mpdServerAsData) as! MPDServer?
			{
				self.mpdServer = server
			}
		}
		else
		{
			Logger.dlog("[+] No MPD server registered yet.")
		}

		if let webServerAsData = NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefWEBServer)
		{
			if let server = NSKeyedUnarchiver.unarchiveObjectWithData(webServerAsData) as! WEBServer?
			{
				self.webServer = server
			}
		}
		else
		{
			Logger.dlog("[+] No WEB server registered yet.")
		}

		self.tableView.reloadData()
	}

	override func viewWillDisappear(animated: Bool)
	{
		super.viewWillDisappear(animated)
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

		// Check MPD server name (optional)
		var serverName = NYXLocalizedString("lbl_server_defaultname")
		if let strName = self.tfMPDName.text where strName.length > 0
		{
			serverName = strName
		}

		// Check MPD hostname / ip
		guard let ip = self.tfMPDHostname.text where ip.length > 0 else
		{
			let alertController = UIAlertController(title:NYXLocalizedString("lbl_alert_servercfg_error"), message:NYXLocalizedString("lbl_alert_servercfg_error_host"), preferredStyle:.Alert)
			let cancelAction = UIAlertAction(title:NYXLocalizedString("lbl_ok"), style:.Cancel) { (action) in
			}
			alertController.addAction(cancelAction)
			self.presentViewController(alertController, animated:true, completion:nil)
			return
		}

		// Check MPD port
		var port = UInt16(6600)
		if let strPort = self.tfMPDPort.text, p = UInt16(strPort)
		{
			port = p
		}

		// Check MPD password (optional)
		var password = ""
		if let strPassword = self.tfMPDPassword.text where strPassword.length > 0
		{
			password = strPassword
		}

		let mpdServer = password.length > 0 ? MPDServer(name:serverName, hostname:ip, port:port, password:password) : MPDServer(name:serverName, hostname:ip, port:port)
		let cnn = MPDConnection(server:mpdServer)
		if cnn.connect()
		{
			self.mpdServer = mpdServer
			let serverAsData = NSKeyedArchiver.archivedDataWithRootObject(mpdServer)
			NSUserDefaults.standardUserDefaults().setObject(serverAsData, forKey:kNYXPrefMPDServer)
		}
		else
		{
			NSUserDefaults.standardUserDefaults().removeObjectForKey(kNYXPrefMPDServer)
			let alertController = UIAlertController(title:NYXLocalizedString("lbl_alert_servercfg_error"), message:NYXLocalizedString("lbl_alert_servercfg_error_msg"), preferredStyle:.Alert)
			let cancelAction = UIAlertAction(title:NYXLocalizedString("lbl_ok"), style:.Cancel) { (action) in
			}
			alertController.addAction(cancelAction)
			self.presentViewController(alertController, animated:true, completion:nil)
		}
		cnn.disconnect()

		// Check web URL (optional)
		if let strURL = self.tfWEBHostname.text where strURL.length > 0
		{
			var port = UInt16(80)
			if let strPort = self.tfWEBPort.text, p = UInt16(strPort)
			{
				port = p
			}

			let webServer = WEBServer(hostname:strURL, port:port)
			var coverName = "cover.jpg"
			if let cn = self.tfWEBCoverName.text where cn.length > 0
			{
				coverName = cn
			}
			webServer.coverName = coverName
			self.webServer = webServer
			let serverAsData = NSKeyedArchiver.archivedDataWithRootObject(webServer)
			NSUserDefaults.standardUserDefaults().setObject(serverAsData, forKey:kNYXPrefWEBServer)
		}
		else
		{
			NSUserDefaults.standardUserDefaults().removeObjectForKey(kNYXPrefWEBServer)
		}

		NSUserDefaults.standardUserDefaults().synchronize()
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
		if !self._keyboardVisible
		{
			return
		}

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
		return 4
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let section = indexPath.section
		let row = indexPath.row
		let cellIdentifier = "\(section):\(row)"
		if let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
		{
			if section == 0
			{
				if row == 0
				{
					if let server = self.mpdServer
					{
						self.tfMPDName.text = server.name
					}
				}
				else if row == 1
				{
					if let server = self.mpdServer
					{
						self.tfMPDHostname.text = server.hostname
					}
				}
				else if row == 2
				{
					if let server = self.mpdServer
					{
						self.tfMPDPort.text = String(server.port)
					}
				}
				else if row == 3
				{
					if let server = self.mpdServer
					{
						self.tfMPDPassword.text = server.password
					}
				}
			}
			else if section == 1
			{
				if row == 0
				{
					if let server = self.webServer
					{
						self.tfWEBHostname.text = server.hostname
					}
				}
				else if row == 1
				{
					if let server = self.webServer
					{
						self.tfWEBPort.text = String(server.port)
					}
				}
				else if row == 2
				{
					if let server = self.webServer
					{
						self.tfWEBCoverName.text = server.coverName
					}
				}
			}
			return cell
		}
		else
		{
			let cell = UITableViewCell(style:.Default, reuseIdentifier:cellIdentifier)
			cell.selectionStyle = .None

			if section == 0
			{
				if row == 0
				{
					cell.textLabel?.text = NYXLocalizedString("lbl_server_name")
					self.tfMPDName = UITextField(frame:CGRect(110.0, 0.0, self.view.frame.width - 120.0, cell.frame.height))
					self.tfMPDName.backgroundColor = cell.backgroundColor
					self.tfMPDName.font = UIFont(name:"AvenirNextCondensed-DemiBold", size:14.0)
					self.tfMPDName.placeholder = NYXLocalizedString("lbl_server_defaultname")
					self.tfMPDName.keyboardType = .Default
					self.tfMPDName.returnKeyType = .Continue
					self.tfMPDName.autocorrectionType = .No
					self.tfMPDName.autocapitalizationType = .None
					self.tfMPDName.delegate = self
					cell.addSubview(self.tfMPDName)
					if let server = self.mpdServer
					{
						self.tfMPDName.text = server.name
					}
				}
				else if row == 1
				{
					cell.textLabel?.text = NYXLocalizedString("lbl_server_host")
					self.tfMPDHostname = UITextField(frame:CGRect(110.0, 0.0, self.view.frame.width - 120.0, cell.frame.height))
					self.tfMPDHostname.backgroundColor = cell.backgroundColor
					self.tfMPDHostname.font = UIFont(name:"AvenirNextCondensed-DemiBold", size:14.0)
					self.tfMPDHostname.placeholder = "127.0.0.1"
					self.tfMPDHostname.keyboardType = .URL
					self.tfMPDHostname.returnKeyType = .Continue
					self.tfMPDHostname.autocorrectionType = .No
					self.tfMPDHostname.autocapitalizationType = .None
					self.tfMPDHostname.delegate = self
					cell.addSubview(self.tfMPDHostname)
					if let server = self.mpdServer
					{
						self.tfMPDHostname.text = server.hostname
					}
				}
				else if row == 2
				{
					cell.textLabel?.text = NYXLocalizedString("lbl_server_port")
					self.tfMPDPort = UITextField(frame:CGRect(110.0, 0.0, self.view.frame.width - 120.0, cell.frame.height))
					self.tfMPDPort.backgroundColor = cell.backgroundColor
					self.tfMPDPort.font = UIFont(name:"AvenirNextCondensed-DemiBold", size:14.0)
					self.tfMPDPort.placeholder = "6600"
					self.tfMPDPort.keyboardType = .NumberPad
					self.tfMPDPort.autocorrectionType = .No
					self.tfMPDPort.delegate = self
					cell.addSubview(self.tfMPDPort)
					if let server = self.mpdServer
					{
						self.tfMPDPort.text = String(server.port)
					}
				}
				else if row == 3
				{
					cell.textLabel?.text = NYXLocalizedString("lbl_server_password")
					self.tfMPDPassword = UITextField(frame:CGRect(110.0, 0.0, self.view.frame.width - 120.0, cell.frame.height))
					self.tfMPDPassword.backgroundColor = cell.backgroundColor
					self.tfMPDPassword.font = UIFont(name:"AvenirNextCondensed-DemiBold", size:14.0)
					self.tfMPDPassword.placeholder = NYXLocalizedString("lbl_optional")
					self.tfMPDPassword.keyboardType = .Default
					self.tfMPDPassword.returnKeyType = .Done
					self.tfMPDPassword.autocorrectionType = .No
					self.tfMPDPassword.autocapitalizationType = .None
					self.tfMPDPassword.delegate = self
					cell.addSubview(self.tfMPDPassword)
					if let server = self.mpdServer
					{
						self.tfMPDPassword.text = server.password
					}
				}
			}
			else if section == 1
			{
				if row == 0
				{
					cell.textLabel?.text = NYXLocalizedString("lbl_server_coverurl")
					self.tfWEBHostname = UITextField(frame:CGRect(140.0, 0.0, self.view.frame.width - 150.0, cell.frame.height))
					self.tfWEBHostname.backgroundColor = cell.backgroundColor
					self.tfWEBHostname.font = UIFont(name:"AvenirNextCondensed-DemiBold", size:14.0)
					self.tfWEBHostname.placeholder = "http://127.0.0.1"
					self.tfWEBHostname.keyboardType = .URL
					self.tfWEBHostname.returnKeyType = .Continue
					self.tfWEBHostname.autocorrectionType = .No
					self.tfWEBHostname.autocapitalizationType = .None
					self.tfWEBHostname.delegate = self
					cell.addSubview(self.tfWEBHostname)
					if let server = self.webServer
					{
						self.tfWEBHostname.text = server.hostname
					}
				}
				else if row == 1
				{
					cell.textLabel?.text = NYXLocalizedString("lbl_server_port")
					self.tfWEBPort = UITextField(frame:CGRect(140.0, 0.0, self.view.frame.width - 150.0, cell.frame.height))
					self.tfWEBPort.backgroundColor = cell.backgroundColor
					self.tfWEBPort.font = UIFont(name:"AvenirNextCondensed-DemiBold", size:14.0)
					self.tfWEBPort.text = "80"
					self.tfWEBPort.keyboardType = .NumberPad
					self.tfWEBPort.autocorrectionType = .No
					self.tfWEBPort.delegate = self
					cell.addSubview(self.tfWEBPort)
					if let server = self.webServer
					{
						self.tfWEBPort.text = String(server.port)
					}
				}
				else if row == 2
				{
					cell.textLabel?.text = NYXLocalizedString("lbl_server_covername")
					self.tfWEBCoverName = UITextField(frame:CGRect(140.0, 0.0, self.view.frame.width - 150.0, cell.frame.height))
					self.tfWEBCoverName.backgroundColor = cell.backgroundColor
					self.tfWEBCoverName.font = UIFont(name:"AvenirNextCondensed-DemiBold", size:14.0)
					self.tfWEBCoverName.text = "cover.jpg"
					self.tfWEBCoverName.keyboardType = .Default
					self.tfWEBCoverName.returnKeyType = .Done
					self.tfWEBCoverName.autocorrectionType = .No
					self.tfWEBCoverName.autocapitalizationType = .None
					self.tfWEBCoverName.delegate = self
					cell.addSubview(self.tfWEBCoverName)
					if let server = self.webServer
					{
						self.tfWEBCoverName.text = server.coverName
					}
				}
				else if row == 3
				{
					cell.textLabel?.text = NYXLocalizedString("lbl_server_coverclearcache")
					cell.textLabel?.textAlignment = .Center
					cell.textLabel?.textColor = UIColor.redColor()
					cell.textLabel?.font = UIFont.boldSystemFontOfSize(16.0)
					cell.selectionStyle = .Default
				}
			}

			return cell
		}
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
		if indexPath.section == 1 && indexPath.row == 3
		{
			let alertController = UIAlertController(title:NYXLocalizedString("lbl_alert_purge_cache_title"), message:NYXLocalizedString("lbl_alert_purge_cache_msg"), preferredStyle:.Alert)
			let cancelAction = UIAlertAction(title:NYXLocalizedString("lbl_cancel"), style:.Cancel) { (action) in
			}
			alertController.addAction(cancelAction)
			let okAction = UIAlertAction(title:NYXLocalizedString("lbl_ok"), style:.Destructive) { (action) in
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
			alertController.addAction(okAction)
			self.presentViewController(alertController, animated:true, completion:nil)
		}
		tableView.deselectRowAtIndexPath(indexPath, animated:true)
	}
}

// MARK: - UITextFieldDelegate
extension ServerVC : UITextFieldDelegate
{
	func textFieldShouldReturn(textField: UITextField) -> Bool
	{
		if textField === self.tfMPDName
		{
			self.tfMPDHostname.becomeFirstResponder()
		}
		else if textField === self.tfMPDHostname
		{
			self.tfMPDPort.becomeFirstResponder()
		}
		else if textField === self.tfMPDPort
		{
			self.tfMPDPassword.becomeFirstResponder()
		}
		else if textField === self.tfMPDPassword
		{
			textField.resignFirstResponder()
		}
		else if textField === self.tfWEBHostname
		{
			self.tfWEBPort.becomeFirstResponder()
		}
		else if textField === self.tfWEBPort
		{
			self.tfWEBCoverName.becomeFirstResponder()
		}
		else
		{
			textField.resignFirstResponder()
		}
		return true
	}
}

/*
// MARK: - MCSessionDelegate
extension ServerVC : MCSessionDelegate
{
	func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID)
	{
		Logger.dlog("\(data)")
	}
	func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState)
	{
		Logger.dlog("\(state)")
	}
	func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID)
	{
		Logger.dlog("\(streamName)")
	}
	func session(session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void)
	{
		Logger.dlog("\(certificate)")
	}
	func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress)
	{
		Logger.dlog("\(resourceName)")
	}
	func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?)
	{
		Logger.dlog("\(error)")
	}
}

// MARK: - MCBrowserViewControllerDelegate
extension ServerVC : MCBrowserViewControllerDelegate
{
	func browserViewControllerDidFinish(browserViewController: MCBrowserViewController)
	{
		Logger.dlog("browserViewControllerDidFinish")
	}
	func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController)
	{
		Logger.dlog("browserViewControllerWasCancelled")
	}
}

// MARK: - MCNearbyServiceBrowserDelegate
extension ServerVC : MCNearbyServiceBrowserDelegate
{
	func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError)
	{
		Logger.alog("didNotStartBrowsingForPeers: \(error)")
	}

	func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?)
	{
		Logger.alog("foundPeer: \(peerID)")
	}

	func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID)
	{
		Logger.alog("lostPeer")
	}
}*/
