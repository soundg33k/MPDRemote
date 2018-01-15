// StatsVC.swift
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


private let headerSectionHeight: CGFloat = 32.0


final class StatsVC : UITableViewController, CenterViewController
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
	// Delegate
	var containerDelegate: ContainerVCDelegate? = nil

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
		titleView.text = NYXLocalizedString("lbl_section_stats")
		navigationItem.titleView = titleView

		lblCellAlbums.text = NYXLocalizedString("lbl_albums")
		lblCellArtists.text = NYXLocalizedString("lbl_artists")
		lblCellSongs.text = NYXLocalizedString("lbl_songs")
		lblCellDBPlaytime.text = NYXLocalizedString("lbl_total_playtime")
		lblCellMPDUptime.text = NYXLocalizedString("lbl_server_uptime")
		lblCellMPDPlaytime.text = NYXLocalizedString("lbl_server_playtime")
		lblCellMPDDBLastUpdate.text = NYXLocalizedString("lbl_server_lastdbupdate")
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

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
		return .default
	}

	// MARK: - IBActions
	@objc @IBAction func showLeftViewAction(_ sender: Any?)
	{
		containerDelegate?.toggleMenu()
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
}

// MARK: - UITableViewDelegate
extension StatsVC
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

		if section == 0
		{
			label.text = NYXLocalizedString("lbl_stats_section_db").uppercased()
		}
		else
		{
			label.text = NYXLocalizedString("lbl_stats_section_server").uppercased()
		}

		return dummy
	}

	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
	{
		return headerSectionHeight
	}
}
