// AlbumDetailVC.swift
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


final class AlbumDetailVC : UIViewController
{
	// MARK: - Public properties
	// Selected album
	var album: Album

	// MARK: - Private properties
	// Header view (cover + album name, artist)
	@IBOutlet private var headerView: AlbumHeaderView! = nil
	// Header height constraint
	@IBOutlet private var headerHeightConstraint: NSLayoutConstraint! = nil
	// Dummy view for shadow
	@IBOutlet private var dummyView: UIView! = nil
	// Tableview for song list
	@IBOutlet private var tableView: UITableView! = nil
	// Label in the navigationbar
	private var titleView: UILabel! = nil

	// MARK: - Initializers
	required init?(coder aDecoder: NSCoder)
	{
		// Dummy
		self.album = Album(name:"")

		super.init(coder:aDecoder)
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Navigation bar title
		titleView = UILabel(frame:CGRect(CGPoint.zero, 100.0, 44.0))
		titleView.numberOfLines = 2
		titleView.textAlignment = .center
		titleView.isAccessibilityElement = false
		titleView.textColor = navigationController?.navigationBar.tintColor
		titleView.backgroundColor = navigationController?.navigationBar.barTintColor
		navigationItem.titleView = titleView

		// Album header view
		let coverSize = NSKeyedUnarchiver.unarchiveObject(with: UserDefaults.standard.data(forKey: kNYXPrefCoverSize)!) as! NSValue
		headerView.coverSize = coverSize.cgSizeValue
		headerHeightConstraint.constant = coverSize.cgSizeValue.height

		// Dummy tableview host, to create a nice shadow effect
		dummyView.layer.shadowPath = UIBezierPath(rect:CGRect(-2.0, 5.0, view.width + 4.0, 4.0)).cgPath
		dummyView.layer.shadowRadius = 3.0
		dummyView.layer.shadowOpacity = 1.0
		dummyView.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
		dummyView.layer.masksToBounds = false

		// Tableview
		tableView.tableFooterView = UIView()
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		// Add navbar shadow
		let navigationBar = navigationController!.navigationBar
		navigationBar.layer.shadowPath = UIBezierPath(rect:CGRect(-2.0, navigationBar.frame.height - 2.0, navigationBar.frame.width + 4.0, 4.0)).cgPath
		navigationBar.layer.shadowRadius = 3.0
		navigationBar.layer.shadowOpacity = 1.0
		navigationBar.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
		navigationBar.layer.masksToBounds = false

		// Update header
		updateHeader()

		// Get songs list if needed
		if album.songs == nil
		{
			MusicDataSource.shared.getSongsForAlbum(album) {
				DispatchQueue.main.async {
					self.updateNavigationTitle()
					self.tableView.reloadData()
				}
			}
		}
		else
		{
			updateNavigationTitle()
			tableView.reloadData()
		}
	}

	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)

		// Remove navbar shadow
		let navigationBar = navigationController!.navigationBar
		navigationBar.layer.shadowPath = nil
		navigationBar.layer.shadowRadius = 0.0
		navigationBar.layer.shadowOpacity = 0.0
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
	private func updateHeader()
	{
		// Update header view
		self.headerView.updateHeaderWithAlbum(album)

		// Don't have all the metadatas
		if album.artist.length == 0
		{
			MusicDataSource.shared.getMetadatasForAlbum(album) {
				DispatchQueue.main.async {
					self.updateHeader()
				}
			}
		}
	}

	private func updateNavigationTitle()
	{
		if let tracks = album.songs
		{
			let total = tracks.reduce(Duration(seconds:0)){$0 + $1.duration}
			let minutes = total.seconds / 60
			let attrs = NSMutableAttributedString(string:"\(tracks.count) \(NYXLocalizedString("lbl_track"))\(tracks.count > 1 ? "s" : "")\n", attributes:[NSFontAttributeName : UIFont(name:"HelveticaNeue-Medium", size:14.0)!])
			attrs.append(NSAttributedString(string:"\(minutes) \(NYXLocalizedString("lbl_minute"))\(minutes > 1 ? "s" : "")", attributes:[NSFontAttributeName : UIFont(name:"HelveticaNeue", size:13.0)!]))
			titleView.attributedText = attrs
		}
	}
}

// MARK: - UITableViewDataSource
extension AlbumDetailVC : UITableViewDataSource
{
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if let tracks = album.songs
		{
			return tracks.count + 1 // dummy
		}
		return 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "io.whine.mpdremote.cell.track", for:indexPath) as! TrackTableViewCell

		if let tracks = album.songs
		{
			// Dummy to let some space for the mini player
			if indexPath.row == tracks.count
			{
				cell.lblTitle.text = ""
				cell.lblTrack.text = ""
				cell.lblDuration.text = ""
				cell.separator.isHidden = true
				cell.selectionStyle = .none
				return cell
			}
			cell.separator.backgroundColor = UIColor.fromRGB(0xE4E4E4)
			cell.separator.isHidden = false

			let track = tracks[indexPath.row]
			cell.lblTrack.text = String(track.trackNumber)
			cell.lblTitle.text = track.title
			let minutes = track.duration.minutesRepresentation().minutes
			let seconds = track.duration.minutesRepresentation().seconds
			cell.lblDuration.text = "\(minutes):\(seconds < 10 ? "0" : "")\(seconds)"

			// Accessibility
			var stra = "\(NYXLocalizedString("lbl_track")) \(track.trackNumber), \(track.title)\n"
			if minutes > 0
			{
				stra += "\(minutes) \(NYXLocalizedString("lbl_minute"))\(minutes > 1 ? "s" : "") "
			}
			if seconds > 0
			{
				stra += "\(seconds) \(NYXLocalizedString("lbl_second"))\(seconds > 1 ? "s" : "")"
			}
			cell.accessibilityLabel = stra
		}

		return cell
	}
}

// MARK: - UITableViewDelegate
extension AlbumDetailVC : UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		tableView.deselectRow(at: indexPath, animated:true)

		// Dummy cell
		guard let tracks = album.songs else {return}
		if indexPath.row >= tracks.count
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
		PlayerController.shared.playTracks(b, random:UserDefaults.standard.bool(forKey: kNYXPrefRandom), loop:UserDefaults.standard.bool(forKey: kNYXPrefRepeat))
	}
}
