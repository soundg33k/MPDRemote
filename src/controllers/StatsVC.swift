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
		titleView.textColor = navigationController?.navigationBar.tintColor
		titleView.text = NYXLocalizedString("lbl_section_stats")
		titleView.backgroundColor = navigationController?.navigationBar.barTintColor
		navigationItem.titleView = titleView
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		MusicDataSource.shared.getStats { (stats: [String : String]) in
			DispatchQueue.main.async {
				self.stats = stats
				self._updateLabels()
			}
		}
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return .portrait
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .lightContent
	}

	// MARK: - Private
	private func _updateLabels()
	{
		lblAlbums.text = stats["albums"] ?? "0"

		lblArtists.text = stats["artists"] ?? "0"

		lblSongs.text = stats["songs"] ?? "0"

		var seconds = UInt(stats["dbplaytime"] ?? "0")!
		var duration = Duration(seconds:seconds)
		lblDBPlaytime.text = _formatDuration(duration)

		seconds = UInt(stats["mpduptime"] ?? "0")!
		duration = Duration(seconds:seconds)
		lblMPDUptime.text = _formatDuration(duration)

		seconds = UInt(stats["mpdplaytime"] ?? "0")!
		duration = Duration(seconds:seconds)
		lblMPDPlaytime.text = _formatDuration(duration)

		let tt = stats["mpddbupdate"] != nil ? TimeInterval(stats["mpddbupdate"]!) : TimeInterval(0)
		let df = DateFormatter()
		df.dateFormat = "dd MMM yyyy, HH:mm"
		let bla = df.string(from: Date(timeIntervalSince1970:tt!))
		lblMPDDBLastUpdate.text = bla
	}

	private func _formatDuration(_ duration: Duration) -> String
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
