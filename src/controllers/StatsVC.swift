// StatsVC.swift
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


final class StatsVC : MenuTVC
{
	// MARK: - Private properties
	// Datasource
	private var stats: [String : String]! = nil
	// Number of albums
	@IBOutlet private var lblAlbums: UILabel! = nil
	// Number of artists
	@IBOutlet private var lblArtists: UILabel! = nil
	// Number of songs
	@IBOutlet private var lblSongs: UILabel! = nil
	// Total time for songs
	@IBOutlet private var lblDBPlaytime: UILabel! = nil
	// Uptime since MPD started
	@IBOutlet private var lblMPDUptime: UILabel! = nil
	// Playtime
	@IBOutlet private var lblMPDPlaytime: UILabel! = nil
	// Last update timestamp
	@IBOutlet private var lblMPDDBLastUpdate: UILabel! = nil
	// Cell Labels
	@IBOutlet private var lblCellAlbums: UILabel! = nil
	@IBOutlet private var lblCellArtists: UILabel! = nil
	@IBOutlet private var lblCellSongs: UILabel! = nil
	@IBOutlet private var lblCellDBPlaytime: UILabel! = nil
	@IBOutlet private var lblCellMPDUptime: UILabel! = nil
	@IBOutlet private var lblCellMPDPlaytime: UILabel! = nil
	@IBOutlet private var lblCellMPDDBLastUpdate: UILabel! = nil
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
		titleView.text = NYXLocalizedString("lbl_section_stats")
		navigationItem.titleView = titleView
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		self.nightModeSettingDidChange(nil)

		MusicDataSource.shared.getStats { (stats: [String : String]) in
			DispatchQueue.main.async {
				self.stats = stats
				self.updateLabels()
			}
		}
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return .portrait
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return isNightModeEnabled() ? .lightContent : .default
	}

	// MARK: - Private
	private func updateLabels()
	{
		lblAlbums.text = stats["albums"] ?? "0"

		lblArtists.text = stats["artists"] ?? "0"

		lblSongs.text = stats["songs"] ?? "0"

		var seconds = UInt(stats["dbplaytime"] ?? "0")!
		var duration = Duration(seconds: seconds)
		lblDBPlaytime.text = formatDuration(duration)

		seconds = UInt(stats["mpduptime"] ?? "0")!
		duration = Duration(seconds: seconds)
		lblMPDUptime.text = formatDuration(duration)

		seconds = UInt(stats["mpdplaytime"] ?? "0")!
		duration = Duration(seconds: seconds)
		lblMPDPlaytime.text = formatDuration(duration)

		let tt = stats["mpddbupdate"] != nil ? TimeInterval(stats["mpddbupdate"]!) : TimeInterval(0)
		let df = DateFormatter()
		df.dateFormat = "dd/MM/yy HH:mm"
		let bla = df.string(from: Date(timeIntervalSince1970: tt!))
		lblMPDDBLastUpdate.text = bla
	}

	private func formatDuration(_ duration: Duration) -> String
	{
		if duration.seconds > 2678400
		{
			let d = duration.monthsRepresentation()
			return "\(d.months)m \(d.days)d \(d.hours)h \(d.minutes)m \(d.seconds)s"
		}
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
			for i in 0...tableView.numberOfSections - 1
			{
				for j in 0...tableView.numberOfRows(inSection: i) - 1
				{
					if let cell = tableView.cellForRow(at: IndexPath(row: j, section: i))
					{
						cell.backgroundColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
					}
				}
			}

			lblAlbums.textColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
			lblArtists.textColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
			lblSongs.textColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
			lblDBPlaytime.textColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
			lblMPDUptime.textColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
			lblMPDPlaytime.textColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
			lblMPDDBLastUpdate.textColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
		}
		else
		{
			navigationController?.navigationBar.barStyle = .default
			titleView.textColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
			tableView.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
			tableView.separatorColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
			for i in 0...tableView.numberOfSections - 1
			{
				for j in 0...tableView.numberOfRows(inSection: i) - 1
				{
					if let cell = tableView.cellForRow(at: IndexPath(row: j, section: i))
					{
						cell.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
					}
				}
			}

			lblAlbums.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
			lblArtists.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
			lblSongs.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
			lblDBPlaytime.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
			lblMPDUptime.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
			lblMPDPlaytime.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
			lblMPDDBLastUpdate.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		}

		lblCellAlbums.textColor = titleView.textColor
		lblCellArtists.textColor = titleView.textColor
		lblCellSongs.textColor = titleView.textColor
		lblCellDBPlaytime.textColor = titleView.textColor
		lblCellMPDUptime.textColor = titleView.textColor
		lblCellMPDPlaytime.textColor = titleView.textColor
		lblCellMPDDBLastUpdate.textColor = titleView.textColor

		setNeedsStatusBarAppearanceUpdate()
	}
}
