// StatsVC.swift
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


final class StatsVC : MenuVC
{
	// MARK: - Private properties
	// Tableview
	private var tableView: UITableView!
	// Datasource
	private var stats: [String : String]! = nil
	// Number of albums
	private var lblAlbums: UILabel! = nil
	// Number of artists
	private var lblArtists: UILabel! = nil
	// Number of songs
	private var lblSongs: UILabel! = nil
	// Total time for songs
	private var lblDBPlaytime: UILabel! = nil
	// Uptime since MPD started
	private var lblMPDUptime: UILabel! = nil
	// Playtime
	private var lblMPDPlaytime: UILabel! = nil
	// Last update timestamp
	private var lblMPDDBLastUpdate: UILabel! = nil

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

		// Navigation bar title
		let titleView = UILabel(frame:CGRect(0.0, 0.0, 100.0, 44.0))
		titleView.font = UIFont(name:"HelveticaNeue-Medium", size:14.0)
		titleView.numberOfLines = 2
		titleView.textAlignment = .Center
		titleView.isAccessibilityElement = false
		titleView.textColor = self.navigationController?.navigationBar.tintColor
		titleView.text = NYXLocalizedString("lbl_section_stats")
		self.navigationItem.titleView = titleView

		// TableView
		self.tableView = UITableView(frame:CGRect(0.0, 0.0, self.view.width, self.view.height - 64.0), style:.Grouped)
		self.tableView.dataSource = self
		self.tableView.delegate = self
		self.tableView.rowHeight = 44.0
		self.tableView.allowsSelection = false
		self.view.addSubview(self.tableView)
	}

	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)

		MPDDataSource.shared.getStats { (stats: [String : String]) in
			dispatch_async(dispatch_get_main_queue()) {
				self.stats = stats
				self.tableView.reloadData()
			}
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

	// MARK: - Private
	private func _formatDuration(duration: Duration) -> String
	{
		if duration.seconds > 86400
		{
			let d = duration.daysRepresentation()
			return "\(d.days)d \(d.hours)h \(d.minutes)m \(d.seconds)s"
		}
		if duration.seconds > 3600
		{
			let d = duration.hoursRepresentation()
			return "\(d.hours)h \(d.minutes)m \(d.seconds)s"
		}
		if duration.seconds > 60
		{
			let d = duration.minutesRepresentation()
			return "\(d.minutes)m \(d.seconds)s"
		}
		return "\(duration.seconds)s"
	}
}

extension StatsVC : UITableViewDataSource
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
		else
		{
			return 3
		}
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
					self.lblAlbums.text = self.stats["albums"] ?? "0"
				}
				else if row == 1
				{
					self.lblArtists.text = self.stats["artists"] ?? "0"
				}
				else if row == 2
				{
					self.lblSongs.text = self.stats["songs"] ?? "0"
				}
				else if row == 3
				{
					let seconds = UInt(self.stats["dbplaytime"] ?? "0")!
					let duration = Duration(seconds:seconds)
					self.lblDBPlaytime.text = self._formatDuration(duration)
				}
			}
			else if section == 1
			{
				if row == 0
				{
					let seconds = UInt(self.stats["mpduptime"] ?? "0")!
					let duration = Duration(seconds:seconds)
					self.lblMPDUptime.text = self._formatDuration(duration)
				}
				else if row == 1
				{
					let seconds = UInt(self.stats["mpdplaytime"] ?? "0")!
					let duration = Duration(seconds:seconds)
					self.lblMPDPlaytime.text = self._formatDuration(duration)
				}
				else if row == 2
				{
					let tt = self.stats["mpddbupdate"] != nil ? NSTimeInterval(self.stats["mpddbupdate"]!) : NSTimeInterval(0)
					let df = NSDateFormatter()
					df.dateFormat = "dd MMM yyyy, HH:mm"
					let bla = df.stringFromDate(NSDate(timeIntervalSince1970:tt!))
					self.lblMPDDBLastUpdate.text = bla
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
					cell.textLabel?.text = NYXLocalizedString("lbl_albums")
					self.lblAlbums = UILabel(frame:CGRect(self.view.width - 70.0, 0.0, 60.0, cell.height))
					self.lblAlbums.backgroundColor = UIColor.whiteColor()
					self.lblAlbums.textAlignment = .Right
					self.lblAlbums.font = UIFont(name:"AvenirNextCondensed-DemiBold", size:14.0)
					cell.addSubview(self.lblAlbums)
				}
				else if row == 1
				{
					cell.textLabel?.text = NYXLocalizedString("lbl_artists")
					self.lblArtists = UILabel(frame:CGRect(self.view.width - 70.0, 0.0, 60.0, cell.height))
					self.lblArtists.backgroundColor = UIColor.whiteColor()
					self.lblArtists.textAlignment = .Right
					self.lblArtists.font = UIFont(name:"AvenirNextCondensed-DemiBold", size:14.0)
					cell.addSubview(self.lblArtists)
				}
				else if row == 2
				{
					cell.textLabel?.text = NYXLocalizedString("lbl_songs")
					self.lblSongs = UILabel(frame:CGRect(self.view.width - 70.0, 0.0, 60.0, cell.height))
					self.lblSongs.backgroundColor = UIColor.whiteColor()
					self.lblSongs.textAlignment = .Right
					self.lblSongs.font = UIFont(name:"AvenirNextCondensed-DemiBold", size:14.0)
					cell.addSubview(self.lblSongs)
				}
				else if row == 3
				{
					cell.textLabel?.text = NYXLocalizedString("lbl_total_playtime")
					self.lblDBPlaytime = UILabel(frame:CGRect(self.view.width - 130.0, 0.0, 120.0, cell.height))
					self.lblDBPlaytime.backgroundColor = UIColor.whiteColor()
					self.lblDBPlaytime.textAlignment = .Right
					self.lblDBPlaytime.font = UIFont(name:"AvenirNextCondensed-DemiBold", size:14.0)
					cell.addSubview(self.lblDBPlaytime)
				}
			}
			else if section == 1
			{
				if row == 0
				{
					cell.textLabel?.text = NYXLocalizedString("lbl_server_uptime")
					self.lblMPDUptime = UILabel(frame:CGRect(self.view.width - 130.0, 0.0, 120.0, cell.height))
					self.lblMPDUptime.backgroundColor = UIColor.whiteColor()
					self.lblMPDUptime.textAlignment = .Right
					self.lblMPDUptime.font = UIFont(name:"AvenirNextCondensed-DemiBold", size:14.0)
					cell.addSubview(self.lblMPDUptime)
				}
				else if row == 1
				{
					cell.textLabel?.text = NYXLocalizedString("lbl_server_playtime")
					self.lblMPDPlaytime = UILabel(frame:CGRect(self.view.width - 130.0, 0.0, 120.0, cell.height))
					self.lblMPDPlaytime.backgroundColor = UIColor.whiteColor()
					self.lblMPDPlaytime.textAlignment = .Right
					self.lblMPDPlaytime.font = UIFont(name:"AvenirNextCondensed-DemiBold", size:14.0)
					cell.addSubview(self.lblMPDPlaytime)
				}
				else if row == 2
				{
					cell.textLabel?.text = NYXLocalizedString("lbl_server_lastdbupdate")
					self.lblMPDDBLastUpdate = UILabel(frame:CGRect(self.view.width - 130.0, 0.0, 120.0, cell.height))
					self.lblMPDDBLastUpdate.backgroundColor = UIColor.whiteColor()
					self.lblMPDDBLastUpdate.textAlignment = .Right
					self.lblMPDDBLastUpdate.font = UIFont(name:"AvenirNextCondensed-DemiBold", size:14.0)
					cell.addSubview(self.lblMPDDBLastUpdate)
				}
			}

			return cell
		}
	}
}

extension StatsVC : UITableViewDelegate
{
	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		if section == 0
		{
			return NYXLocalizedString("lbl_section_database")
		}
		else
		{
			return NYXLocalizedString("lbl_section_server")
		}
	}
}
