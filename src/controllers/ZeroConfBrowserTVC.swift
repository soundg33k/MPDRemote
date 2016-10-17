// ZeroConfBrowserTVC.swift
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


protocol ZeroConfBrowserTVCDelegate : class
{
	func audioServerDidChange()
}


final class ZeroConfBrowserTVC : UITableViewController
{
	// MARK: - Public properties
	// Delegate
	weak var delegate: ZeroConfBrowserTVCDelegate? = nil

	// MARK: - Private properties
	// Zeroconf explorer
	fileprivate var _explorer: ZeroConfExplorer! = nil
	// List of servers found
	fileprivate var _servers = [Server]()

	// MARK: - Initializer
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder:aDecoder)

		self._explorer = ZeroConfExplorer()
		self._explorer.delegate = self
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Navigation bar title
		let titleView = UILabel(frame:CGRect(0.0, 0.0, 100.0, 44.0))
		titleView.font = UIFont(name:"HelveticaNeue-Medium", size:14.0)
		titleView.numberOfLines = 2
		titleView.textAlignment = .center
		titleView.isAccessibilityElement = false
		titleView.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		titleView.text = NYXLocalizedString("lbl_header_server_zeroconf")
		navigationItem.titleView = titleView
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		self._explorer.searchForServices(type: "_mpd._tcp.")
	}

	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)
		self._explorer.stopSearch()
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
	@IBAction private func done(_ sender: Any?)
	{
		self.dismiss(animated: true, completion: nil)
	}

	// MARK: - Private
	func currentAudioServer() -> AudioServer?
	{
		if let serverAsData = UserDefaults.standard.data(forKey: kNYXPrefMPDServer)
		{
			if let server = NSKeyedUnarchiver.unarchiveObject(with: serverAsData) as! AudioServer?
			{
				return server
			}
		}
		return nil
	}
}

// MARK: - UITableViewDataSource
extension ZeroConfBrowserTVC
{
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return _servers.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "io.whine.mpdremote.cell.zeroconf", for:indexPath) as! ZeroConfServerTableViewCell

		let server = _servers[indexPath.row]
		cell.lblName.text = server.name
		cell.lblHostname.text = server.hostname + ":" + String(server.port)
		if let currentServer = currentAudioServer()
		{
			if currentServer == server
			{
				cell.accessoryType = .checkmark
			}
			else
			{
				cell.accessoryType = .none
			}
		}
		else
		{
			cell.accessoryType = .none
		}

		return cell
	}
}

// MARK: - UITableViewDelegate
extension ZeroConfBrowserTVC
{
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		// Check if same server
		tableView.deselectRow(at: indexPath, animated: true)
		let selectedServer = _servers[indexPath.row]
		if let currentServer = currentAudioServer()
		{
			if selectedServer == currentServer
			{
				return
			}
		}

		// Different server, update
		let mpdServer = AudioServer(name:selectedServer.name, hostname:selectedServer.hostname, port:selectedServer.port, password:"", type:.mpd)
		let serverAsData = NSKeyedArchiver.archivedData(withRootObject: mpdServer)
		UserDefaults.standard.set(serverAsData, forKey:kNYXPrefMPDServer)
		UserDefaults.standard.synchronize()

		self.tableView.reloadData()
		delegate?.audioServerDidChange()
	}
}

extension ZeroConfBrowserTVC : ZeroConfExplorerDelegate
{
	internal func didFindServer(_ server: Server)
	{
		_servers = _explorer.services.map({$0.value})
		self.tableView.reloadData()
	}
}
