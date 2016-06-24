// AlbumDetailVC.swift
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


final class AlbumDetailVC : UIViewController
{
	// MARK: - Public properties
	// Albums list
	var albums: [Album]! = nil
	// Album index in the list
	var selectedIndex: Int = 0

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
		let coverSize = NSKeyedUnarchiver.unarchiveObject(with: UserDefaults.standard().data(forKey: kNYXPrefCoverSize)!) as! NSValue
		headerView.coverSize = coverSize.cgSizeValue()
		headerHeightConstraint.constant = coverSize.cgSizeValue().height
		//headerView.navDelegate = self

		// Dummy tableview host, to create a nice shadow effect
		dummyView.layer.shadowPath = UIBezierPath(rect:CGRect(-2.0, 5.0, view.width + 4.0, 4.0)).cgPath
		dummyView.layer.shadowRadius = 3.0
		dummyView.layer.shadowOpacity = 1.0
		dummyView.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
		dummyView.layer.masksToBounds = false

		// Tableview
		tableView.tableFooterView = UIView()

		// Notif for frame changes
		NotificationCenter.default().addObserver(self, selector:#selector(playingTrackChangedNotification(_:)), name:kNYXNotificationPlayingTrackChanged, object:nil)
		NotificationCenter.default().addObserver(self, selector:#selector(playerStatusChangedNotification(_:)), name:kNYXNotificationPlayerStatusChanged, object:nil)
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
		_updateHeader()

		// Get songs list if needed
		let album = _currentAlbum()
		if album.songs == nil
		{
			MPDDataSource.shared.getSongsForAlbum(album) {
				DispatchQueue.main.async {
					self._updateNavigationTitle()
					self.tableView.reloadData()
				}
			}
		}
		else
		{
			_updateNavigationTitle()
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

	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
	{
		return .portrait
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle
	{
		return .lightContent
	}

	// MARK: - Notifications
	func playingTrackChangedNotification(_ aNotification: Notification?)
	{
		tableView.reloadData()
	}

	func playerStatusChangedNotification(_ aNotification: Notification?)
	{
		tableView.reloadData()
	}

	// MARK: - Private
	private func _nextAlbum() -> Album?
	{
		if selectedIndex < (albums.count - 1)
		{
			return albums[selectedIndex + 1]
		}
		return nil
	}

	private func _previousAlbum() -> Album?
	{
		if selectedIndex > 0
		{
			return albums[selectedIndex - 1]
		}
		return nil
	}

	private func _currentAlbum() -> Album
	{
		return albums[selectedIndex]
	}

	private func _fetchMetadatasForSideAlbums()
	{
		if let nextAlbum = _nextAlbum()
		{
			MPDDataSource.shared.getMetadatasForAlbum(nextAlbum) {}
		}
		if let previousAlbum = _previousAlbum()
		{
			MPDDataSource.shared.getMetadatasForAlbum(previousAlbum) {}
		}
	}

	private func _updateHeader()
	{
		// get current album
		let album = _currentAlbum()

		// Update header view
		self.headerView.updateHeaderWithAlbum(album)

		// Don't have all the metadatas
		if album.artist.length == 0
		{
			MPDDataSource.shared.getMetadatasForAlbum(album) {
				DispatchQueue.main.async {
					self._updateHeader()
				}
			}
		}
	}

	private func _updateNavigationTitle()
	{
		let album = _currentAlbum()
		if let tracks = album.songs
		{
			let total = tracks.reduce(Duration(seconds:0)){$0 + $1.duration}
			let minutes = total.seconds / 60
			let attrs = NSMutableAttributedString(string:"\(tracks.count) \(NYXLocalizedString("lbl_track"))\(tracks.count > 1 ? "s" : "")\n", attributes:[NSFontAttributeName : UIFont(name:"HelveticaNeue-Medium", size:14.0)!])
			attrs.append(AttributedString(string:"\(minutes) \(NYXLocalizedString("lbl_minute"))\(minutes > 1 ? "s" : "")", attributes:[NSFontAttributeName : UIFont(name:"HelveticaNeue", size:13.0)!]))
			titleView.attributedText = attrs
		}
	}
}

// MARK: - UITableViewDataSource
extension AlbumDetailVC : UITableViewDataSource
{
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if let tracks = _currentAlbum().songs
		{
			return tracks.count + 1 // dummy
		}
		return 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "io.whine.mpdremote.cell.track", for:indexPath) as! TrackTableViewCell

		if let tracks = _currentAlbum().songs
		{
			// Dummy to let some space for the mini player
			if indexPath.row == tracks.count
			{
				cell.lblTitle.text = ""
				cell.lblTrack.text = ""
				cell.lblDuration.text = ""
				cell.selectionStyle = .none
				return cell
			}

			let track = tracks[indexPath.row]
			cell.lblTrack.text = String(track.trackNumber)
			cell.lblTitle.text = track.title
			let minutes = track.duration.minutesRepresentation().minutes
			let seconds = track.duration.minutesRepresentation().seconds
			cell.lblDuration.text = "\(minutes):\(seconds < 10 ? "0" : "")\(seconds)"

			// Display playing image if this track is the current one being played
			if let currentPlayingTrack = MPDPlayer.shared.currentTrack
			{
				if currentPlayingTrack == track
				{
					if MPDPlayer.shared.status == .paused
					{
						cell.ivPlayback.image = #imageLiteral(resourceName: "btn-play")
					}
					else
					{
						cell.ivPlayback.image = #imageLiteral(resourceName: "btn-pause")
					}
					cell.ivPlayback.alpha = 1.0
					cell.lblTrack.alpha = 0.0
				}
				else
				{
					cell.ivPlayback.alpha = 0.0
					cell.lblTrack.alpha = 1.0
				}
			}
			else
			{
				cell.ivPlayback.alpha = 0.0
				cell.lblTrack.alpha = 1.0
			}

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
		guard let tracks = _currentAlbum().songs else {return}
		if indexPath.row == tracks.count
		{
			return
		}

		// Toggle play / pause for the current track
		if let currentPlayingTrack = MPDPlayer.shared.currentTrack
		{
			let selectedTrack = tracks[indexPath.row]
			if selectedTrack == currentPlayingTrack
			{
				let cell = tableView.cellForRow(at: indexPath) as? TrackTableViewCell
				if MPDPlayer.shared.status == .playing
				{
					cell?.ivPlayback.image = #imageLiteral(resourceName: "btn-play")
				}
				else
				{
					cell?.ivPlayback.image = #imageLiteral(resourceName: "btn-pause")
				}
				MPDPlayer.shared.togglePause()
				return
			}
		}

		let b = tracks.filter({$0.trackNumber >= (indexPath.row + 1)})
		MPDPlayer.shared.playTracks(b, random:UserDefaults.standard().bool(forKey: kNYXPrefRandom), loop:UserDefaults.standard().bool(forKey: kNYXPrefRepeat))
	}
}

// MARK: - HeaderScrollViewDelegate
/*extension AlbumDetailVC : HeaderScrollViewDelegate
{
	func requestNextAlbum() -> Album?
	{
		return _nextAlbum()
	}

	func requestPreviousAlbum() -> Album?
	{
		return _previousAlbum()
	}

	func shouldShowNextAlbum() -> Bool
	{
		if selectedIndex < (albums.count - 1)
		{
			selectedIndex += 1

			let album = _currentAlbum()
			if album.songs == nil
			{
				MPDDataSource.shared.getSongsForAlbum(album) {
					DispatchQueue.main.async {
						self._updateHeader()
						self._updateNavigationTitle()
						self.tableView.reloadData()
						self.headerView.itemChanged()
					}
				}
			}
			else
			{
				_updateHeader()
				_updateNavigationTitle()
				tableView.reloadData()
				headerView.itemChanged()
			}

			return true
		}
		return false
	}

	func shouldShowPreviousAlbum() -> Bool
	{
		if selectedIndex > 0
		{
			selectedIndex -= 1

			let album = _currentAlbum()
			if album.songs == nil
			{
				MPDDataSource.shared.getSongsForAlbum(album) {
					DispatchQueue.main.async {
						self._updateHeader()
						self._updateNavigationTitle()
						self.tableView.reloadData()
						self.headerView.itemChanged()
					}
				}
			}
			else
			{
				_updateHeader()
				_updateNavigationTitle()
				tableView.reloadData()
				headerView.itemChanged()
			}

			return true
		}
		return false
	}
}*/
