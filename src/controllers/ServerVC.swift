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


final class ServerVC : MenuTVC
{
	// MARK: - Private properties
	// MPD Server name
	@IBOutlet private var tfMPDName: UITextField!
	// MPD Server hostname
	@IBOutlet private var tfMPDHostname: UITextField!
	// MPD Server port
	@IBOutlet private var tfMPDPort: UITextField!
	// MPD Server password
	@IBOutlet private var tfMPDPassword: UITextField!
	// WEB Server hostname
	@IBOutlet private var tfWEBHostname: UITextField!
	// WEB Server port
	@IBOutlet private var tfWEBPort: UITextField!
	// Cover name
	@IBOutlet private var tfWEBCoverName: UITextField!
	// MPD Server
	private var mpdServer: MPDServer?
	// WEB Server for covers
	private var webServer: WEBServer?
	// Indicate that the keyboard is visible, flag
	private var _keyboardVisible = false
	// Zeroconf browser
	private var serviceBrowser: NSNetServiceBrowser!
	// List of ZC servers found
	private var zcList = [NSNetService]()

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Navigation bar title
		let titleView = UILabel(frame:CGRect(0.0, 0.0, 100.0, 44.0))
		titleView.font = UIFont(name:"HelveticaNeue-Medium", size:14.0)
		titleView.numberOfLines = 2
		titleView.textAlignment = .Center
		titleView.isAccessibilityElement = false
		titleView.textColor = self.navigationController?.navigationBar.tintColor
		titleView.text = NYXLocalizedString("lbl_header_server_cfg")
		titleView.backgroundColor = self.navigationController?.navigationBar.barTintColor
		self.navigationItem.titleView = titleView

		// Keyboard appearance notifications
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(keyboardDidShowNotification(_:)), name:UIKeyboardDidShowNotification, object:nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(keyboardDidHideNotification(_:)), name:UIKeyboardDidHideNotification, object:nil)
	}

	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)

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

			self.serviceBrowser = NSNetServiceBrowser()
			self.serviceBrowser.delegate = self
			self.serviceBrowser.searchForServicesOfType("_mpd._tcp.", inDomain:"")
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

		self._updateFields()
	}

	override func viewWillDisappear(animated: Bool)
	{
		super.viewWillDisappear(animated)

		// Stop zeroconf
		self.zcList.removeAll()
		if let s = self.serviceBrowser
		{
			s.stop()
		}
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
	@IBAction func validateSettingsAction(sender: AnyObject?)
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

	// MARK: - Private
	func _updateFields()
	{
		if let server = self.mpdServer
		{
			self.tfMPDName.text = server.name
			self.tfMPDHostname.text = server.hostname
			self.tfMPDPort.text = String(server.port)
			self.tfMPDPassword.text = server.password
		}
		else
		{
			self.tfMPDName.text = ""
			self.tfMPDHostname.text = ""
			self.tfMPDPort.text = "6600"
			self.tfMPDPassword.text = ""
		}

		if let server = self.webServer
		{
			self.tfWEBHostname.text = server.hostname
			self.tfWEBPort.text = String(server.port)
			self.tfWEBCoverName.text = server.coverName
		}
		else
		{
			self.tfWEBHostname.text = ""
			self.tfWEBPort.text = "8080"
			self.tfWEBCoverName.text = "cover.jpg"
		}
	}

	func _resolvZeroconfServices()
	{
		if let service = self.zcList[safe:0]
		{
			service.delegate = self
			service.resolveWithTimeout(5)
		}
	}
}

// MARK: - UITableViewDelegate
extension ServerVC
{
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
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

// MARK: - NSNetServiceBrowserDelegate
extension ServerVC : NSNetServiceBrowserDelegate
{
	func netServiceBrowserWillSearch(browser: NSNetServiceBrowser)
	{
		Logger.dlog("netServiceBrowserWillSearch")
	}
	func netServiceBrowserDidStopSearch(browser: NSNetServiceBrowser)
	{
		Logger.dlog("netServiceBrowserDidStopSearch")
	}
	func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber])
	{
		Logger.dlog("didNotSearch : \(errorDict)")
	}
	func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool)
	{
		Logger.dlog("didFindService")
		zcList.append(service)
		if !moreComing
		{
			self._resolvZeroconfServices()
		}
		
	}
	func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool)
	{
		Logger.dlog("didRemoveService")
	}
}

// MARK: - NSNetServiceDelegate
extension ServerVC : NSNetServiceDelegate
{
	func netServiceDidResolveAddress(sender: NSNetService)
	{
		Logger.dlog("netServiceDidResolveAddress: \(sender.name)")
		
		guard let addresses = sender.addresses else {return}
		
		var found = false
		var tmpIP = ""
		for addressBytes in addresses where found == false
		{
			let inetAddressPointer = UnsafePointer<sockaddr_in>(addressBytes.bytes)
			var inetAddress = inetAddressPointer.memory
			if inetAddress.sin_family == sa_family_t(AF_INET)
			{
				let ipStringBuffer = UnsafeMutablePointer<Int8>.alloc(Int(INET6_ADDRSTRLEN))
				let ipString = inet_ntop(Int32(inetAddress.sin_family), &inetAddress.sin_addr, ipStringBuffer, UInt32(INET6_ADDRSTRLEN))
				if let ip = String.fromCString(ipString)
				{
					tmpIP = ip
					found = true
				}
				ipStringBuffer.dealloc(Int(INET6_ADDRSTRLEN))
			}
			else if inetAddress.sin_family == sa_family_t(AF_INET6)
			{
				let inetAddressPointer6 = UnsafePointer<sockaddr_in6>(addressBytes.bytes)
				var inetAddress6 = inetAddressPointer6.memory
				let ipStringBuffer = UnsafeMutablePointer<Int8>.alloc(Int(INET6_ADDRSTRLEN))
				let ipString = inet_ntop(Int32(inetAddress6.sin6_family), &inetAddress6.sin6_addr, ipStringBuffer, UInt32(INET6_ADDRSTRLEN))
				if let ip = String.fromCString(ipString)
				{
					tmpIP = ip
					found = true
				}
				ipStringBuffer.dealloc(Int(INET6_ADDRSTRLEN))
			}

			if found
			{
				self.tfMPDName.text = sender.name
				self.tfMPDPort.text = String(sender.port)
				self.tfMPDHostname.text = tmpIP
			}
		}
	}
	func netService(sender: NSNetService, didNotResolve errorDict: [String : NSNumber])
	{
		Logger.dlog("didNotResolve \(sender)")
	}
	func netServiceDidStop(sender: NSNetService)
	{
		Logger.dlog("netServiceDidStop \(sender.name)")
	}
}
