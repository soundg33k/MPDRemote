// TrackListTableView.swift
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


final class TrackListTableView : UIView
{
	/// Table view
	private(set) var tableView: UITableView! = nil
	/// Album
	var album: Album! = nil
	{
		didSet
		{
			if album != nil && album.tracks == nil
			{
				MusicDataSource.shared.getTracksForAlbum(album) {
					DispatchQueue.main.async {
						self.tableView.reloadData()
					}
				}
			}
		}
	}
	// MARK: - Public properties
	// Delegate
	weak var delegate: TrackListTableViewDelegate? = nil

	// MARK: - Initializers
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
		self.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)

		self.tableView = UITableView(frame: self.bounds, style: .plain)
		self.tableView.register(TrackTableViewCell.classForCoder(), forCellReuseIdentifier: "fr.whine.mpdremote.cell.track")
		self.tableView.dataSource = self
		self.tableView.delegate = self
		self.tableView.separatorStyle = .none
		let bgView = UIView()
		bgView.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		self.tableView.backgroundView = bgView
		self.addSubview(self.tableView)

		let singleTapWith2Fingers = UITapGestureRecognizer()
		singleTapWith2Fingers.numberOfTapsRequired = 1
		singleTapWith2Fingers.numberOfTouchesRequired = 2
		singleTapWith2Fingers.delaysTouchesBegan = true
		singleTapWith2Fingers.addTarget(self, action: #selector(singleTap(_:)))
		self.tableView.addGestureRecognizer(singleTapWith2Fingers)
	}

	// MARK: - Gestures
	func singleTap(_ gesture: UITapGestureRecognizer)
	{
		if gesture.state == .ended
		{
			self.delegate?.didTapWithTwoFingers(self)
		}
	}
}

// MARK: - UITableViewDataSource
extension TrackListTableView : UITableViewDataSource
{
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if album == nil
		{
			return 0
		}

		if let tracks = album.tracks
		{
			return tracks.count
		}

		return 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "fr.whine.mpdremote.cell.track", for: indexPath) as! TrackTableViewCell

		if let tracks = album.tracks
		{
			let track = tracks[indexPath.row]
			cell.lblTrack.text = String(track.trackNumber)
			cell.lblTitle.text = track.name
			let minutes = track.duration.minutesRepresentation().minutes
			let seconds = track.duration.minutesRepresentation().seconds
			cell.lblDuration.text = "\(minutes):\(seconds < 10 ? "0" : "")\(seconds)"

			// Accessibility
			var stra = "\(NYXLocalizedString("lbl_track")) \(track.trackNumber), \(track.name)\n"
			if minutes > 0
			{
				stra += "\(minutes) \(minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes")) "
			}
			if seconds > 0
			{
				stra += "\(seconds) \(seconds == 1 ? NYXLocalizedString("lbl_second") : NYXLocalizedString("lbl_seconds"))"
			}
			cell.accessibilityLabel = stra

			Logger.dlog("\(cell.contentView.frame)")
		}

		return cell
	}
}

// MARK: - UITableViewDelegate
extension TrackListTableView : UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		// Dummy cell
		guard let tracks = album.tracks else
		{
			return
		}

		// Toggle play / pause for the current track
		if let currentPlayingTrack = PlayerController.shared.currentTrack
		{
			let selectedTrack = tracks[indexPath.row]
			if selectedTrack == currentPlayingTrack
			{
				PlayerController.shared.togglePause()
				return
			}
		}

		let b = tracks.filter({$0.trackNumber >= (indexPath.row + 1)})
		PlayerController.shared.playTracks(b, shuffle: UserDefaults.standard.bool(forKey: kNYXPrefMPDShuffle), loop: UserDefaults.standard.bool(forKey: kNYXPrefMPDRepeat))
	}
}

protocol TrackListTableViewDelegate : class
{
	func didTapWithTwoFingers(_ view: TrackListTableView)
}
