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
	@IBOutlet private var headerView: HeaderScrollView! = nil
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
		self.titleView = UILabel(frame:CGRect(CGPointZero, 100.0, 44.0))
		self.titleView.numberOfLines = 2
		self.titleView.textAlignment = .Center
		self.titleView.isAccessibilityElement = false
		self.titleView.textColor = self.navigationController?.navigationBar.tintColor
		self.titleView.backgroundColor = self.navigationController?.navigationBar.barTintColor
		self.navigationItem.titleView = self.titleView

		// Album header view
		let coverSize = NSKeyedUnarchiver.unarchiveObjectWithData(NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefCoverSize)!) as! NSValue
		self.headerView.coverWidth = coverSize.CGSizeValue().width
		self.headerHeightConstraint.constant = coverSize.CGSizeValue().height
		self.headerView.navDelegate = self

		// Dummy tableview host, to create a nice shadow effect
		dummyView.layer.shadowPath = UIBezierPath(rect:CGRect(-2.0, 5.0, self.view.width + 4.0, 4.0)).CGPath
		dummyView.layer.shadowRadius = 3.0
		dummyView.layer.shadowOpacity = 1.0
		dummyView.layer.shadowColor = UIColor.blackColor().CGColor
		dummyView.layer.masksToBounds = false

		// Tableview
		self.tableView.tableFooterView = UIView()

		// Notif for frame changes
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(playingTrackChangedNotification(_:)), name:kNYXNotificationPlayingTrackChanged, object:nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(playerStatusChangedNotification(_:)), name:kNYXNotificationPlayerStatusChanged, object:nil)
	}

	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)

		// Add navbar shadow
		let navigationBar = self.navigationController!.navigationBar
		navigationBar.layer.shadowPath = UIBezierPath(rect:CGRect(-2.0, navigationBar.frame.height - 2.0, navigationBar.frame.width + 4.0, 4.0)).CGPath
		navigationBar.layer.shadowRadius = 3.0
		navigationBar.layer.shadowOpacity = 1.0
		navigationBar.layer.shadowColor = UIColor.blackColor().CGColor
		navigationBar.layer.masksToBounds = false

		// Update header
		self._updateHeader()

		// Get songs list if needed
		let album = self._currentAlbum()
		if album.songs == nil
		{
			MPDDataSource.shared.getSongsForAlbum(album, callback: {
				dispatch_async(dispatch_get_main_queue()) {
					self._updateNavigationTitle()
					self.tableView.reloadData()
				}
			})
		}
		else
		{
			self._updateNavigationTitle()
			self.tableView.reloadData()
		}
	}

	override func viewWillDisappear(animated: Bool)
	{
		super.viewWillDisappear(animated)

		// Remove navbar shadow
		let navigationBar = self.navigationController!.navigationBar
		navigationBar.layer.shadowPath = nil
		navigationBar.layer.shadowRadius = 0.0
		navigationBar.layer.shadowOpacity = 0.0
	}

	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
	{
		return .Portrait
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle
	{
		return .LightContent
	}

	// MARK: - Notifications
	func playingTrackChangedNotification(aNotification: NSNotification?)
	{
		self.tableView.reloadData()
	}

	func playerStatusChangedNotification(aNotification: NSNotification?)
	{
		self.tableView.reloadData()
	}

	// MARK: - Private
	private func _nextAlbum() -> Album?
	{
		if self.selectedIndex < (self.albums.count - 1)
		{
			return self.albums[self.selectedIndex + 1]
		}
		return nil
	}

	private func _previousAlbum() -> Album?
	{
		if self.selectedIndex > 0
		{
			return self.albums[self.selectedIndex - 1]
		}
		return nil
	}

	private func _currentAlbum() -> Album
	{
		return self.albums[self.selectedIndex]
	}

	private func _fetchMetadatasForSideAlbums()
	{
		if let nextAlbum = self._nextAlbum()
		{
			MPDDataSource.shared.getMetadatasForAlbum(nextAlbum, callback:{})
		}
		if let previousAlbum = self._previousAlbum()
		{
			MPDDataSource.shared.getMetadatasForAlbum(previousAlbum, callback:{})
		}
	}

	private func _updateHeader()
	{
		// get current album
		let album = self._currentAlbum()

		// Update header view
		self.headerView.mainView.updateHeaderWithAlbum(album)

		// Don't have all the metadatas
		if album.artist.length == 0
		{
			MPDDataSource.shared.getMetadatasForAlbum(album, callback: {
				dispatch_async(dispatch_get_main_queue()) {
					self._updateHeader()
				}
			})
		}
	}

	private func _updateNavigationTitle()
	{
		let album = self._currentAlbum()
		if let tracks = album.songs
		{
			let total = tracks.reduce(Duration(seconds:0)){$0 + $1.duration}
			let minutes = total.seconds / 60
			let attrs = NSMutableAttributedString(string:"\(tracks.count) \(NYXLocalizedString("lbl_track"))\(tracks.count > 1 ? "s" : "")\n", attributes:[NSFontAttributeName : UIFont(name:"HelveticaNeue-Medium", size:14.0)!])
			attrs.appendAttributedString(NSAttributedString(string:"\(minutes) \(NYXLocalizedString("lbl_minute"))\(minutes > 1 ? "s" : "")", attributes:[NSFontAttributeName : UIFont(name:"HelveticaNeue", size:13.0)!]))
			self.titleView.attributedText = attrs
		}
	}
}

// MARK: - UITableViewDataSource
extension AlbumDetailVC : UITableViewDataSource
{
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if let tracks = self._currentAlbum().songs
		{
			return tracks.count + 1 // dummy
		}
		return 0
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCellWithIdentifier("io.whine.mpdremote.cell.track", forIndexPath:indexPath) as! TrackTableViewCell

		if let tracks = self._currentAlbum().songs
		{
			// Dummy to let some space for the mini player
			if indexPath.row == tracks.count
			{
				cell.lblTitle.text = ""
				cell.lblTrack.text = ""
				cell.lblDuration.text = ""
				cell.selectionStyle = .None
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
					if MPDPlayer.shared.status == .Paused
					{
						cell.ivPlayback.image = UIImage(named:"btn-play")
					}
					else
					{
						cell.ivPlayback.image = UIImage(named:"btn-pause")
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
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		tableView.deselectRowAtIndexPath(indexPath, animated:true)

		// Dummy cell
		guard let tracks = self._currentAlbum().songs else {return}
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
				let cell = tableView.cellForRowAtIndexPath(indexPath) as? TrackTableViewCell
				if MPDPlayer.shared.status == .Playing
				{
					let img = UIImage(named:"btn-play")
					cell?.ivPlayback.image = img
				}
				else
				{
					let img = UIImage(named:"btn-pause")
					cell?.ivPlayback.image = img
				}
				MPDPlayer.shared.togglePause()
				return
			}
		}

		let b = tracks.filter({$0.trackNumber >= (indexPath.row + 1)})
		MPDPlayer.shared.playTracks(b, random:NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRandom), loop:NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRepeat))
	}
}

// MARK: - HeaderScrollViewDelegate
extension AlbumDetailVC : HeaderScrollViewDelegate
{
	func requestNextAlbum() -> Album?
	{
		return self._nextAlbum()
	}

	func requestPreviousAlbum() -> Album?
	{
		return self._previousAlbum()
	}

	func shouldShowNextAlbum() -> Bool
	{
		if self.selectedIndex < (self.albums.count - 1)
		{
			self.selectedIndex += 1

			let album = self._currentAlbum()
			if album.songs == nil
			{
				MPDDataSource.shared.getSongsForAlbum(album, callback:{
					dispatch_async(dispatch_get_main_queue()) {
						self._updateHeader()
						self._updateNavigationTitle()
						self.tableView.reloadData()
						self.headerView.itemChanged()
					}
				})
			}
			else
			{
				self._updateHeader()
				self._updateNavigationTitle()
				self.tableView.reloadData()
				self.headerView.itemChanged()
			}

			return true
		}
		return false
	}

	func shouldShowPreviousAlbum() -> Bool
	{
		if self.selectedIndex > 0
		{
			self.selectedIndex -= 1

			let album = self._currentAlbum()
			if album.songs == nil
			{
				MPDDataSource.shared.getSongsForAlbum(album, callback:{
					dispatch_async(dispatch_get_main_queue()) {
						self._updateHeader()
						self._updateNavigationTitle()
						self.tableView.reloadData()
						self.headerView.itemChanged()
					}
				})
			}
			else
			{
				self._updateHeader()
				self._updateNavigationTitle()
				self.tableView.reloadData()
				self.headerView.itemChanged()
			}

			return true
		}
		return false
	}
}
