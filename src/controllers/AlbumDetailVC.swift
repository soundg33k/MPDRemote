// AlbumDetailVC.swift
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
	// Dummy view to color the nav bar
	@IBOutlet private var colorView: UIView! = nil
	// Label in the navigationbar
	private var titleView: UILabel! = nil
	// Random button
	private var btnRandom: UIBarButtonItem! = nil
	// Repeat button
	private var btnRepeat: UIBarButtonItem! = nil

	// MARK: - Initializers
	required init?(coder aDecoder: NSCoder)
	{
		// Dummy
		self.album = Album(name: "")

		super.init(coder: aDecoder)
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Navigation bar title
		titleView = UILabel(frame: CGRect(.zero, 100.0, 44.0))
		titleView.numberOfLines = 2
		titleView.textAlignment = .center
		titleView.isAccessibilityElement = false
		titleView.textColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
		navigationItem.titleView = titleView

		// Album header view
		let coverSize = NSKeyedUnarchiver.unarchiveObject(with: UserDefaults.standard.data(forKey: kNYXPrefCoversSize)!) as! NSValue
		headerView.coverSize = coverSize.cgSizeValue
		headerHeightConstraint.constant = coverSize.cgSizeValue.height

		// Dummy tableview host, to create a nice shadow effect
		dummyView.layer.shadowPath = UIBezierPath(rect: CGRect(-2.0, 5.0, view.width + 4.0, 4.0)).cgPath
		dummyView.layer.shadowRadius = 3.0
		dummyView.layer.shadowOpacity = 1.0
		dummyView.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
		dummyView.layer.masksToBounds = false

		// Tableview
		tableView.tableFooterView = UIView()

		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackChangedNotification(_:)), name: .playingTrackChanged, object: nil)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		// Add navbar shadow
		if let navigationBar = navigationController?.navigationBar
		{
			navigationBar.layer.shadowPath = UIBezierPath(rect: CGRect(-2.0, navigationBar.frame.height - 2.0, navigationBar.frame.width + 4.0, 4.0)).cgPath
			navigationBar.layer.shadowRadius = 3.0
			navigationBar.layer.shadowOpacity = 1.0
			navigationBar.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
			navigationBar.layer.masksToBounds = false

			let loop = UserDefaults.standard.bool(forKey: kNYXPrefMPDRepeat)
			btnRepeat = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-repeat").withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(toggleRepeatAction(_:)))
			btnRepeat.tintColor = loop ? #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1) : #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
			btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

			let rand = UserDefaults.standard.bool(forKey: kNYXPrefMPDShuffle)
			btnRandom = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-random").withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(toggleRandomAction(_:)))
			btnRandom.tintColor = rand ? #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1) : #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
			btnRandom.accessibilityLabel = NYXLocalizedString(rand ? "lbl_random_disable" : "lbl_random_enable")

			navigationItem.rightBarButtonItems = [btnRandom, btnRepeat]
		}

		// Update header
		updateHeader()

		// Get songs list if needed
		if album.tracks == nil
		{
			MusicDataSource.shared.getTracksForAlbum(album) {
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
		if let navigationBar = navigationController?.navigationBar
		{
			navigationBar.layer.shadowPath = nil
			navigationBar.layer.shadowRadius = 0.0
			navigationBar.layer.shadowOpacity = 0.0
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

	// MARK: - Private
	private func updateHeader()
	{
		// Update header view
		headerView.updateHeaderWithAlbum(album)
		colorView.backgroundColor = headerView.backgroundColor

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
		if let tracks = album.tracks
		{
			let total = tracks.reduce(Duration(seconds: 0)){$0 + $1.duration}
			let minutes = total.seconds / 60
			let attrs = NSMutableAttributedString(string: "\(tracks.count) \(tracks.count == 1 ? NYXLocalizedString("lbl_track") : NYXLocalizedString("lbl_tracks"))\n", attributes:[NSFontAttributeName : UIFont(name: "HelveticaNeue-Medium", size: 14.0)!])
			attrs.append(NSAttributedString(string: "\(minutes) \(minutes == 1 ? NYXLocalizedString("lbl_minute") : NYXLocalizedString("lbl_minutes"))", attributes: [NSFontAttributeName : UIFont(name: "HelveticaNeue", size: 13.0)!]))
			titleView.attributedText = attrs
		}
	}

	// MARK: - Buttons actions
	func toggleRandomAction(_ sender: Any?)
	{
		let prefs = UserDefaults.standard
		let random = !prefs.bool(forKey: kNYXPrefMPDShuffle)

		btnRandom.tintColor = random ? #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1) : #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		prefs.set(random, forKey: kNYXPrefMPDShuffle)
		prefs.synchronize()

		PlayerController.shared.setRandom(random)
	}

	func toggleRepeatAction(_ sender: Any?)
	{
		let prefs = UserDefaults.standard
		let loop = !prefs.bool(forKey: kNYXPrefMPDRepeat)

		btnRepeat.tintColor = loop ? #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1) : #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

		prefs.set(loop, forKey: kNYXPrefMPDRepeat)
		prefs.synchronize()

		PlayerController.shared.setRepeat(loop)
	}

	// MARK: - Notifications
	func playingTrackChangedNotification(_ notification: Notification)
	{
		tableView.reloadData()
	}
}

// MARK: - UITableViewDataSource
extension AlbumDetailVC : UITableViewDataSource
{
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if let tracks = album.tracks
		{
			return tracks.count + 1 // dummy
		}
		return 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "fr.whine.mpdremote.cell.track", for: indexPath) as! TrackTableViewCell
		cell.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		cell.contentView.backgroundColor = cell.backgroundColor
		cell.lblTitle.backgroundColor = cell.backgroundColor
		cell.lblTrack.backgroundColor = cell.backgroundColor
		cell.lblDuration.backgroundColor = cell.backgroundColor

		if let tracks = album.tracks
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

			cell.separator.backgroundColor = UIColor(rgb: 0xE4E4E4)
			cell.separator.isHidden = false
			cell.lblTitle.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
			cell.lblTrack.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
			cell.lblDuration.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)

			let track = tracks[indexPath.row]
			cell.lblTrack.text = String(track.trackNumber)
			cell.lblTitle.text = track.name
			let minutes = track.duration.minutesRepresentation().minutes
			let seconds = track.duration.minutesRepresentation().seconds
			cell.lblDuration.text = "\(minutes):\(seconds < 10 ? "0" : "")\(seconds)"

			if PlayerController.shared.currentTrack == track
			{
				cell.lblTrack.font = UIFont(name: "HelveticaNeue-Bold", size: 10)
				cell.lblTitle.font = UIFont(name: "HelveticaNeue-CondensedBlack", size: 14)
				cell.lblDuration.font = UIFont(name: "HelveticaNeue-Medium", size: 10)
			}
			else
			{
				cell.lblTrack.font = UIFont(name: "HelveticaNeue", size: 10)
				cell.lblTitle.font = UIFont(name: "HelveticaNeue-Medium", size: 14)
				cell.lblDuration.font = UIFont(name: "HelveticaNeue-Light", size: 10)
			}

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
		}

		return cell
	}
}

// MARK: - UITableViewDelegate
extension AlbumDetailVC : UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		// Dummy cell
		guard let tracks = album.tracks else {return}
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
		PlayerController.shared.playTracks(b, shuffle: UserDefaults.standard.bool(forKey: kNYXPrefMPDShuffle), loop: UserDefaults.standard.bool(forKey: kNYXPrefMPDRepeat))
	}
}

// MARK: - Peek & Pop
extension AlbumDetailVC
{
	override var previewActionItems: [UIPreviewActionItem]
	{
		let playAction = UIPreviewAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action, viewController) in
			PlayerController.shared.playAlbum(self.album, shuffle: false, loop: false)
			MiniPlayerView.shared.stayHidden = false
		}

		let shuffleAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action, viewController) in
			PlayerController.shared.playAlbum(self.album, shuffle: true, loop: false)
			MiniPlayerView.shared.stayHidden = false
		}

		let addQueueAction = UIPreviewAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action, viewController) in
			PlayerController.shared.addAlbumToQueue(self.album)
			MiniPlayerView.shared.stayHidden = false
		}

		return [playAction, shuffleAction, addQueueAction]
	}
}
