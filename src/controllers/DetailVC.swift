// DetailVC.swift
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


final class DetailVC : UIViewController
{
	// MARK: - Properties
	// Albums list
	var albums: [Album]! = nil
	// Album index in the list
	var selectedIndex: Int = 0
	// Header view (cover + album name, artist)
	private(set) var headerView: HeaderScrollView! = nil
	// Tableview for song list
	private(set) var tableView: UITableView! = nil
	// Label in the navigationbar
	private(set) var titleView: UILabel! = nil
	// Random button
	private(set) var btnRandom: UIButton! = nil
	// Repeat button
	private(set) var btnRepeat: UIButton! = nil

	// MARK: - Initializers
	init()
	{
		super.init(nibName:nil, bundle:nil)
	}

	required init?(coder aDecoder: NSCoder)
	{
	    fatalError("init(coder:) has not been implemented")
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()
		self.automaticallyAdjustsScrollViewInsets = false

		// Navigation bar title
		self.titleView = UILabel(frame:CGRect(CGPointZero, 100.0, 44.0))
		self.titleView.font = UIFont.systemFontOfSize(12.0)
		self.titleView.numberOfLines = 2
		self.titleView.textAlignment = .Center
		self.titleView.isAccessibilityElement = false
		self.titleView.textColor = self.navigationController?.navigationBar.tintColor
		self.navigationItem.titleView = self.titleView

		// Album header view
		let coverSize = NSKeyedUnarchiver.unarchiveObjectWithData(NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefCoverSize)!) as! NSValue
		self.headerView = HeaderScrollView(frame:CGRect(CGPointZero, self.view.width, coverSize.CGSizeValue().height))
		self.headerView.navDelegate = self
		self.view.addSubview(self.headerView)

		// Dummy tableview host
		let yOffset = CGFloat(64.0) // at this point the self.view.height doesn't include the navbar height, so there's an offset
		//let height = MiniPlayerView.shared.visible ? self.view.frame.height - self.headerView.frame.height - playerViewHeight - yDecal : self.view.frame.height - self.headerView.frame.height - yDecal
		let height = self.view.frame.height - self.headerView.frame.height - yOffset
		let dummy = UIView(frame:CGRect(0.0, self.headerView.frame.bottom, self.view.frame.width, height))
		dummy.layer.shadowPath = UIBezierPath(rect:CGRect(-2.0, 5.0, self.view.frame.width + 4.0, 4.0)).CGPath
		dummy.layer.shadowRadius = 3.0
		dummy.layer.shadowOpacity = 1.0
		dummy.layer.shadowColor = UIColor.blackColor().CGColor
		dummy.layer.masksToBounds = false
		self.view.addSubview(dummy)

		// Tableview
		self.tableView = UITableView(frame:dummy.bounds, style:.Plain)
		self.tableView.registerClass(TrackTableViewCell.classForCoder(), forCellReuseIdentifier:"io.whine.mpdremote.cell.track")
		self.tableView.dataSource = self
		self.tableView.delegate = self
		self.tableView.backgroundColor = UIColor.fromRGB(0xECECEC)
		self.tableView.separatorInset = UIEdgeInsets(top:0.0, left:8.0, bottom:0.0, right:8.0)
		self.tableView.separatorColor = UIColor.fromRGB(0xCCCCCC)
		self.tableView.rowHeight = 44.0
		dummy.addSubview(self.tableView)

		// Random/repeat buttons
		let random = NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRandom)
		let imageRandom = UIImage(named:"btn-random")
		self.btnRandom = UIButton(type:.Custom)
		self.btnRandom.frame = CGRect((self.navigationController?.navigationBar.frame.width)! - 44.0, 0.0, 44.0, 44.0)
		self.btnRandom.setImage(imageRandom?.imageTintedWithColor(UIColor.fromRGB(0xCC0000))?.imageWithRenderingMode(.AlwaysOriginal), forState:.Normal)
		self.btnRandom.setImage(imageRandom?.imageTintedWithColor(UIColor.whiteColor())?.imageWithRenderingMode(.AlwaysOriginal), forState:.Selected)
		self.btnRandom.selected = random
		self.btnRandom.addTarget(self, action:#selector(DetailVC.toggleRandomAction(_:)), forControlEvents:.TouchUpInside)
		self.btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_shuffle_disable" : "lbl_shuffle_enable")
		self.navigationController?.navigationBar.addSubview(self.btnRandom)

		let loop = NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRepeat)
		let imageRepeat = UIImage(named:"btn-repeat")
		self.btnRepeat = UIButton(type:.Custom)
		self.btnRepeat.frame = CGRect((self.navigationController?.navigationBar.frame.width)! - 88.0, 0.0, 44.0, 44.0)
		self.btnRepeat.setImage(imageRepeat?.imageTintedWithColor(UIColor.fromRGB(0xCC0000))?.imageWithRenderingMode(.AlwaysOriginal), forState:.Normal)
		self.btnRepeat.setImage(imageRepeat?.imageTintedWithColor(UIColor.whiteColor())?.imageWithRenderingMode(.AlwaysOriginal), forState:.Selected)
		self.btnRepeat.selected = loop
		self.btnRepeat.addTarget(self, action:#selector(DetailVC.toggleRepeatAction(_:)), forControlEvents:.TouchUpInside)
		self.btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")
		self.navigationController?.navigationBar.addSubview(self.btnRepeat)

		// Notif for frame
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(miniPlayerWillShow(_:)), name:kNYXNotificationMiniPlayerViewWillShow, object:nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(miniPlayerWillHide(_:)), name:kNYXNotificationMiniPlayerViewWillHide, object:nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(currentPlayingTrackChanged(_:)), name:kNYXNotificationCurrentPlayingTrackChanged, object:nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(currentPlayingStatusChanged(_:)), name:kNYXNotificationPlayerStatusChanged, object:nil)
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

		// Buttons display
		self.btnRandom.alpha = 1.0
		self.btnRepeat.alpha = 1.0

		// Get songs list if needed
		let album = self._currentAlbum()
		if album.songs == nil
		{
			MPDDataSource.shared.getSongsForAlbum(album, callback: {
				dispatch_async(dispatch_get_main_queue(), {
					self._updateNavigationTitle()
					self.tableView.reloadData()
				})
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

		// Buttons display
		self.btnRandom.alpha = 0.0
		self.btnRepeat.alpha = 0.0
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
	func toggleRandomAction(sender: AnyObject?)
	{
		let prefs = NSUserDefaults.standardUserDefaults()
		let random = !prefs.boolForKey(kNYXPrefRandom)

		self.btnRandom.selected = random
		self.btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_shuffle_disable" : "lbl_shuffle_enable")

		prefs.setBool(random, forKey:kNYXPrefRandom)
		prefs.synchronize()

		MPDPlayer.shared.setRandom(random)
	}

	func toggleRepeatAction(sender: AnyObject?)
	{
		let prefs = NSUserDefaults.standardUserDefaults()
		let loop = !prefs.boolForKey(kNYXPrefRepeat)

		self.btnRepeat.selected = loop
		self.btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")
		
		prefs.setBool(loop, forKey:kNYXPrefRepeat)
		prefs.synchronize()

		MPDPlayer.shared.setRepeat(loop)
	}

	// MARK: - Notifications
	func miniPlayerWillShow(aNotification: NSNotification?)
	{
		/*self.view.frame = CGRect(self.view.origin, self.view.width, self.view.height - playerViewHeight)
		self.tableView.superview?.frame = CGRect(0.0, self.headerView.bottom, self.view.width, self.view.height - self.headerView.height)
		self.tableView.frame = (self.tableView.superview?.bounds)!*/
	}

	func miniPlayerWillHide(aNotification: NSNotification?)
	{
		/*self.view.frame = CGRect(self.view.origin, self.view.width, self.view.height + playerViewHeight)
		self.tableView.superview?.frame = CGRect(0.0, self.headerView.bottom, self.view.width, self.view.height - self.headerView.height)
		self.tableView.frame = (self.tableView.superview?.bounds)!*/
	}

	func currentPlayingTrackChanged(aNotification: NSNotification?)
	{
		self.tableView.reloadData()
	}

	func currentPlayingStatusChanged(aNotification: NSNotification?)
	{
		self.tableView.reloadData()
	}

	// MARK: - Private
	private func _nextAlbum() -> Album?
	{
		if selectedIndex < (self.albums.count - 1)
		{
			return self.albums[self.selectedIndex + 1]
		}
		return nil
	}

	private func _previousAlbum() -> Album?
	{
		if selectedIndex > 0
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
			MPDDataSource.shared.getMetadatasForAlbum(nextAlbum, callback: {
				dispatch_async(dispatch_get_main_queue(), {
					self._updateHeader()
				})
			})
		}
		if let previousAlbum = self._previousAlbum()
		{
			MPDDataSource.shared.getMetadatasForAlbum(previousAlbum, callback: {
				dispatch_async(dispatch_get_main_queue(), {
					self._updateHeader()
				})
			})
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
				dispatch_async(dispatch_get_main_queue(), {
					self._updateHeader()
				})
			})
		}
	}

	private func _updateNavigationTitle()
	{
		let album = self._currentAlbum()
		if let tracks = album.songs
		{
			var duration = UInt(0)
			for track in tracks
			{
				duration += track.duration.seconds
			}
			let minutes = duration / 60
			self.titleView.text = "\(tracks.count) \(NYXLocalizedString("lbl_track"))\(tracks.count > 1 ? "s" : "")\n\(minutes) \(NYXLocalizedString("lbl_minute"))\(minutes > 1 ? "s" : "")"
		}
	}
}

// MARK: - UITableViewDataSource
extension DetailVC : UITableViewDataSource
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
						cell.imgPlayback.image = UIImage(named:"btn-play")
					}
					else
					{
						cell.imgPlayback.image = UIImage(named:"btn-pause")
					}
					cell.imgPlayback.alpha = 1.0
					cell.lblTrack.alpha = 0.0
				}
				else
				{
					cell.imgPlayback.alpha = 0.0
					cell.lblTrack.alpha = 1.0
				}
			}
			else
			{
				cell.imgPlayback.alpha = 0.0
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
extension DetailVC : UITableViewDelegate
{
	func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
	{
		let c = cell as! TrackTableViewCell
		c.lblDuration.frame = CGRect(c.contentView.bounds.right - 32.0 - 8.0, (c.frame.height - 14.0) * 0.5, 32.0, 14.0)
		c.lblTitle.frame = CGRect(c.lblTrack.frame.right + 8.0, (c.frame.height - 18.0) * 0.5, ((c.lblDuration.frame.left - 8.0) - (c.lblTrack.frame.right + 8.0)), 18.0)
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		tableView.deselectRowAtIndexPath(indexPath, animated:true)

		if let tracks = self._currentAlbum().songs
		{
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
						cell?.imgPlayback.image = img
					}
					else
					{
						let img = UIImage(named:"btn-pause")
						cell?.imgPlayback.image = img
					}
					MPDPlayer.shared.togglePausePlayback()
					return
				}
			}
			
			let b = tracks.filter({$0.trackNumber >= (indexPath.row + 1)})
			MPDPlayer.shared.playTracks(b, random:NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRandom), loop:NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRepeat))
		}
	}
}

// MARK: - HeaderScrollViewDelegate
extension DetailVC : HeaderScrollViewDelegate
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
					dispatch_async(dispatch_get_main_queue(), {
						self._updateHeader()
						self.tableView.reloadData()
						self.headerView.itemChanged()
					})
				})
			}
			else
			{
				self._updateHeader()
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
					dispatch_async(dispatch_get_main_queue(), {
						self._updateHeader()
						self.tableView.reloadData()
						self.headerView.itemChanged()
					})
				})
			}
			else
			{
				self._updateHeader()
				self.tableView.reloadData()
				self.headerView.itemChanged()
			}
			
			return true
		}
		return false
	}
}
