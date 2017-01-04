// RootVC.swift
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


private let __sideSpan = CGFloat(10.0)
private let __columns = 3
private let __insets = UIEdgeInsets(top: __sideSpan, left: __sideSpan, bottom: __sideSpan, right: __sideSpan)


final class RootVC : MenuVC
{
	// MARK: - Private properties
	// Albums view
	@IBOutlet fileprivate var collectionView: UICollectionView!
	// Top constraint for collection view
	@IBOutlet fileprivate var topConstraint: NSLayoutConstraint!
	// Search bar
	fileprivate var searchView: UIView! = nil
	fileprivate var searchBar: UISearchBar! = nil
	// Button in the navigationbar
	fileprivate var titleView: UIButton! = nil
	// Random button
	fileprivate var btnRandom: UIButton! = nil
	// Repeat button
	fileprivate var btnRepeat: UIButton! = nil
	// Should show the search view, flag
	fileprivate var searchBarVisible = false
	// Is currently searching, flag
	fileprivate var searching = false
	// Search results
	fileprivate var searchResults = [Any]()
	// Long press gesture is recognized, flag
	fileprivate var longPressRecognized = false
	// Keep track of download operations to eventually cancel them
	fileprivate var _downloadOperations = [String : Operation]()
	// View to change the type of items in the collection view
	fileprivate var _typeChoiceView: TypeChoiceView! = nil
	// Active display type
	fileprivate var _displayType = DisplayType(rawValue: UserDefaults.standard.integer(forKey: kNYXPrefDisplayType))!
	// Audio server changed
	fileprivate var _serverChanged = false

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Remove back button label
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
		navigationController?.navigationBar.barStyle = .default

		// Customize navbar
		let navigationBar = (navigationController?.navigationBar)!

		// Searchbar
		searchView = UIView(frame: CGRect(0.0, -64.0, navigationBar.width, 64.0))
		searchView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		searchBar = UISearchBar(frame: navigationBar.frame)
		searchBar.searchBarStyle = .minimal
		searchBar.barTintColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		searchBar.tintColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
		(searchBar.value(forKey: "searchField") as? UITextField)?.textColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
		searchBar.showsCancelButton = true
		searchBar.delegate = self
		searchView.addSubview(searchBar)

		// Navigation bar title
		titleView = UIButton(frame: CGRect(0.0, 0.0, 100.0, navigationBar.height))
		titleView.addTarget(self, action: #selector(changeTypeAction(_:)), for: .touchUpInside)
		navigationItem.titleView = titleView

		// Random button
		let random = UserDefaults.standard.bool(forKey: kNYXPrefMPDShuffle)
		let imageRandom = #imageLiteral(resourceName: "btn-random")
		btnRandom = UIButton(type: .custom)
		btnRandom.frame = CGRect((navigationController?.navigationBar.frame.width)! - 44.0, 0.0, 44.0, 44.0)
		btnRandom.setImage(imageRandom.tinted(withColor: #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1))?.withRenderingMode(.alwaysOriginal), for: .normal)
		btnRandom.setImage(imageRandom.tinted(withColor: #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1))?.withRenderingMode(.alwaysOriginal), for: .highlighted)
		btnRandom.setImage(imageRandom.tinted(withColor: #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1))?.withRenderingMode(.alwaysOriginal), for: .selected)
		btnRandom.isSelected = random
		btnRandom.addTarget(self, action: #selector(toggleRandomAction(_:)), for: .touchUpInside)
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")
		navigationController?.navigationBar.addSubview(btnRandom)

		// Repeat button
		let loop = UserDefaults.standard.bool(forKey: kNYXPrefMPDRepeat)
		let imageRepeat = #imageLiteral(resourceName: "btn-repeat")
		btnRepeat = UIButton(type: .custom)
		btnRepeat.frame = CGRect((navigationController?.navigationBar.frame.width)! - 88.0, 0.0, 44.0, 44.0)
		btnRepeat.setImage(imageRepeat.tinted(withColor: #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1))?.withRenderingMode(.alwaysOriginal), for: .normal)
		btnRepeat.setImage(imageRepeat.tinted(withColor: #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1))?.withRenderingMode(.alwaysOriginal), for: .highlighted)
		btnRepeat.setImage(imageRepeat.tinted(withColor: #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1))?.withRenderingMode(.alwaysOriginal), for: .selected)
		btnRepeat.isSelected = loop
		btnRepeat.addTarget(self, action: #selector(toggleRepeatAction(_:)), for: .touchUpInside)
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")
		navigationController?.navigationBar.addSubview(btnRepeat)

		// Create collection view
		collectionView.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
		collectionView.indicatorStyle = .black
		collectionView.register(RootCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: "io.whine.mpdremote.cell.album")
		(collectionView.collectionViewLayout as! UICollectionViewFlowLayout).sectionInset = __insets;
		let w = ceil((UIScreen.main.bounds.width / CGFloat(__columns)) - (2 * __sideSpan))
		(collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize = CGSize(w, w + 20.0);
		collectionView.isPrefetchingEnabled = false

		// Longpress
		let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
		longPress.minimumPressDuration = 0.5
		longPress.delaysTouchesBegan = true
		collectionView.addGestureRecognizer(longPress)

		// Double tap
		let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
		doubleTap.numberOfTapsRequired = 2
		doubleTap.numberOfTouchesRequired = 1
		doubleTap.delaysTouchesBegan = true
		collectionView.addGestureRecognizer(doubleTap)

		_ = MiniPlayerView.shared.visible

		NotificationCenter.default.addObserver(self, selector: #selector(audioServerConfigurationDidChange(_:)), name: .audioServerConfigurationDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(miniPlayShouldExpandNotification(_:)), name: .miniPlayerShouldExpand, object: nil)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		// Initialize the mpd connection
		if MusicDataSource.shared.server == nil
		{
			if let serverAsData = UserDefaults.standard.data(forKey: kNYXPrefMPDServer)
			{
				if let server = NSKeyedUnarchiver.unarchiveObject(with: serverAsData) as! AudioServer?
				{
					// Data source
					MusicDataSource.shared.server = server
					_ = MusicDataSource.shared.initialize()
					if _displayType != .albums
					{
						// Always fetch the albums list
						MusicDataSource.shared.getListForDisplayType(.albums) {}
					}
					MusicDataSource.shared.getListForDisplayType(_displayType) {
						DispatchQueue.main.async {
							self.collectionView.reloadData()
							self.updateNavigationTitle()
						}
					}

					// Player
					PlayerController.shared.server = server
					_ = PlayerController.shared.initialize()
				}
				else
				{
					let alertController = UIAlertController(title: NYXLocalizedString("lbl_alert_servercfg_error"), message:NYXLocalizedString("lbl_alert_server_need_check"), preferredStyle: .alert)
					let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel, handler: nil)
					alertController.addAction(cancelAction)
					present(alertController, animated: true, completion: nil)
				}
			}
			else
			{
				Logger.alog("[+] No MPD server registered yet.")
				let serverVC = APP_DELEGATE().serverVC
				APP_DELEGATE().window?.rootViewController = serverVC
			}
		}

		// Since we are in search mode, show the bar
		if searchView.superview == nil
		{
			navigationController?.view.addSubview(searchView)
		}
		
		// Deselect cell
		if let idxs = collectionView.indexPathsForSelectedItems
		{
			for indexPath in idxs
			{
				collectionView.deselectItem(at: indexPath, animated: true)
			}
		}

		// Audio server changed
		if _serverChanged
		{
			// Refresh view
			MusicDataSource.shared.getListForDisplayType(_displayType) {
				DispatchQueue.main.async {
					self.collectionView.reloadData()
					self.collectionView.setContentOffset(.zero, animated: false) // Scroll to top
					self.updateNavigationTitle()
				}
			}
			_serverChanged = false
		}
	}

	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)

		APP_DELEGATE().operationQueue.cancelAllOperations()
		_downloadOperations.removeAll()

		if searchView.superview != nil
		{
			searchView.removeFromSuperview()
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

	override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
		super.prepare(for: segue, sender: sender)
		
		if segue.identifier == "root-albums-to-detail-album"
		{
			let row = collectionView.indexPathsForSelectedItems![0].row
			let album = searching ? searchResults[row] as! Album : MusicDataSource.shared.albums[row]
			let vc = segue.destination as! AlbumDetailVC
			vc.album = album
		}
		else if segue.identifier == "root-genres-to-artists"
		{
			let row = collectionView.indexPathsForSelectedItems![0].row
			let genre = searching ? searchResults[row] as! Genre : MusicDataSource.shared.genres[row]
			let vc = segue.destination as! ArtistsVC
			vc.genre = genre
		}
		else if segue.identifier == "root-artists-to-albums"
		{
			let row = collectionView.indexPathsForSelectedItems![0].row
			let artist = searching ? searchResults[row] as! Artist : MusicDataSource.shared.artists[row]
			let vc = segue.destination as! AlbumsVC
			vc.artist = artist
		}
		else if segue.identifier == "root-playlists-to-detail-playlist"
		{
			let row = collectionView.indexPathsForSelectedItems![0].row
			let playlist = searching ? searchResults[row] as! Playlist : MusicDataSource.shared.playlists[row]
			let vc = segue.destination as! PlaylistDetailVC
			vc.playlist = playlist
		}
	}

	// MARK: - Gestures
	func doubleTap(_ gest: UITapGestureRecognizer)
	{
		if gest.state != .ended
		{
			return
		}

		if let indexPath = collectionView.indexPathForItem(at: gest.location(in: collectionView))
		{
			switch _displayType
			{
				case .albums:
					let album = searching ? searchResults[indexPath.row] as! Album : MusicDataSource.shared.albums[indexPath.row]
					PlayerController.shared.playAlbum(album, shuffle: UserDefaults.standard.bool(forKey: kNYXPrefMPDShuffle), loop: UserDefaults.standard.bool(forKey: kNYXPrefMPDRepeat))
				case .artists:
					let artist = searching ? searchResults[indexPath.row] as! Artist : MusicDataSource.shared.artists[indexPath.row]
					MusicDataSource.shared.getAlbumsForArtist(artist) {
						MusicDataSource.shared.getTracksForAlbums(artist.albums) {
							let ar = artist.albums.flatMap({$0.tracks}).flatMap({$0})
							PlayerController.shared.playTracks(ar, shuffle: UserDefaults.standard.bool(forKey: kNYXPrefMPDShuffle), loop: UserDefaults.standard.bool(forKey: kNYXPrefMPDRepeat))
						}
					}
				case .genres:
					let genre = searching ? searchResults[indexPath.row] as! Genre : MusicDataSource.shared.genres[indexPath.row]
					MusicDataSource.shared.getAlbumsForGenre(genre) {
						MusicDataSource.shared.getTracksForAlbums(genre.albums) {
							let ar = genre.albums.flatMap({$0.tracks}).flatMap({$0})
							PlayerController.shared.playTracks(ar, shuffle: UserDefaults.standard.bool(forKey: kNYXPrefMPDShuffle), loop: UserDefaults.standard.bool(forKey: kNYXPrefMPDRepeat))
						}
					}
				case .playlists:
					let playlist = searching ? searchResults[indexPath.row] as! Playlist : MusicDataSource.shared.playlists[indexPath.row]
					PlayerController.shared.playPlaylist(playlist, shuffle: UserDefaults.standard.bool(forKey: kNYXPrefMPDShuffle), loop: UserDefaults.standard.bool(forKey: kNYXPrefMPDRepeat))
			}
		}
	}

	func longPress(_ gest: UILongPressGestureRecognizer)
	{
		if longPressRecognized
		{
			return
		}
		longPressRecognized = true

		if let indexPath = collectionView.indexPathForItem(at: gest.location(in: collectionView))
		{
			MiniPlayerView.shared.stayHidden = true
			MiniPlayerView.shared.hide()
			let cell = collectionView.cellForItem(at: indexPath) as! RootCollectionViewCell
			cell.longPressed = true

			let alertController = UIAlertController(title: nil, message: nil, preferredStyle:.actionSheet)
			let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel) { (action) in
				self.longPressRecognized = false
				cell.longPressed = false
				MiniPlayerView.shared.stayHidden = false
			}
			alertController.addAction(cancelAction)

			switch _displayType
			{
				case .albums:
					let album = searching ? searchResults[indexPath.row] as! Album : MusicDataSource.shared.albums[indexPath.row]
					let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
						PlayerController.shared.playAlbum(album, shuffle: false, loop: false)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						PlayerController.shared.playAlbum(album, shuffle: true, loop: false)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action) in
						PlayerController.shared.addAlbumToQueue(album)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(addQueueAction)
				case .artists:
					let artist = searching ? searchResults[indexPath.row] as! Artist : MusicDataSource.shared.artists[indexPath.row]
					let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
						MusicDataSource.shared.getAlbumsForArtist(artist) {
							MusicDataSource.shared.getTracksForAlbums(artist.albums) {
								let ar = artist.albums.flatMap({$0.tracks}).flatMap({$0})
								PlayerController.shared.playTracks(ar, shuffle: false, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						MusicDataSource.shared.getAlbumsForArtist(artist) {
							MusicDataSource.shared.getTracksForAlbums(artist.albums) {
								let ar = artist.albums.flatMap({$0.tracks}).flatMap({$0})
								PlayerController.shared.playTracks(ar, shuffle: true, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action) in
						MusicDataSource.shared.getAlbumsForArtist(artist) {
							for album in artist.albums
							{
								PlayerController.shared.addAlbumToQueue(album)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(addQueueAction)
				case .genres:
					let genre = self.searching ? self.searchResults[indexPath.row] as! Genre : MusicDataSource.shared.genres[indexPath.row]
					let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
						MusicDataSource.shared.getAlbumsForGenre(genre) {
							MusicDataSource.shared.getTracksForAlbums(genre.albums) {
								let ar = genre.albums.flatMap({$0.tracks}).flatMap({$0})
								PlayerController.shared.playTracks(ar, shuffle: false, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						MusicDataSource.shared.getAlbumsForGenre(genre) {
							MusicDataSource.shared.getTracksForAlbums(genre.albums) {
								let ar = genre.albums.flatMap({$0.tracks}).flatMap({$0})
								PlayerController.shared.playTracks(ar, shuffle: true, loop: false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_addqueue"), style: .default) { (action) in
						MusicDataSource.shared.getAlbumsForGenre(genre) {
							for album in genre.albums
							{
								PlayerController.shared.addAlbumToQueue(album)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(addQueueAction)
				case .playlists:
					let playlist = self.searching ? self.searchResults[indexPath.row] as! Playlist : MusicDataSource.shared.playlists[indexPath.row]
					let playAction = UIAlertAction(title: NYXLocalizedString("lbl_play"), style: .default) { (action) in
						PlayerController.shared.playPlaylist(playlist, shuffle: false, loop: false)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title: NYXLocalizedString("lbl_alert_playalbum_shuffle"), style: .default) { (action) in
						PlayerController.shared.playPlaylist(playlist, shuffle: true, loop: false)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
			}

			present(alertController, animated: true, completion: nil)
		}
	}

	// MARK: - Buttons actions
	func changeTypeAction(_ sender: UIButton?)
	{
		if _typeChoiceView == nil
		{
			_typeChoiceView = TypeChoiceView(frame: CGRect(0.0, kNYXTopInset, collectionView.width, 176.0))
			_typeChoiceView.delegate = self
		}

		if _typeChoiceView.superview != nil
		{ // Is visible
			self.collectionView.contentInset = UIEdgeInsets(top: kNYXTopInset, left: 0.0, bottom: 0.0, right: 0.0)
			topConstraint.constant = 0.0
			UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
				self.view.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
				self.view.layoutIfNeeded()
				if MusicDataSource.shared.currentCollection(self._displayType).count == 0
				{
					self.collectionView.contentOffset = CGPoint(0, 64)
				}
				else
				{
					self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
				}
			}, completion:{ finished in
				self._typeChoiceView.removeFromSuperview()
			})
		}
		else
		{ // Is hidden
			_typeChoiceView.tableView.reloadData()
			view.insertSubview(_typeChoiceView, belowSubview:collectionView)
			topConstraint.constant = _typeChoiceView.bottom;

			UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
				self.collectionView.contentInset = .zero
				self.view.backgroundColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
				//self.view.layoutIfNeeded()
			}, completion:nil)
		}
	}

	func toggleRandomAction(_ sender: Any?)
	{
		let prefs = UserDefaults.standard
		let random = !prefs.bool(forKey: kNYXPrefMPDShuffle)

		btnRandom.isSelected = random
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		prefs.set(random, forKey: kNYXPrefMPDShuffle)
		prefs.synchronize()

		PlayerController.shared.setRandom(random)
	}

	func toggleRepeatAction(_ sender: Any?)
	{
		let prefs = UserDefaults.standard
		let loop = !prefs.bool(forKey: kNYXPrefMPDRepeat)

		btnRepeat.isSelected = loop
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

		prefs.set(loop, forKey: kNYXPrefMPDRepeat)
		prefs.synchronize()

		PlayerController.shared.setRepeat(loop)
	}

	// MARK: - Private
	fileprivate func showNavigationBar(animated: Bool = true)
	{
		searchBar.endEditing(true)
		UIView.animate(withDuration: animated ? 0.35 : 0.0, delay: 0.0, options: .curveEaseOut, animations: {
			self.searchView.y = -self.searchView.height
		}, completion:{ finished in
			self.searchBarVisible = false
		})
	}

	fileprivate func hideNavigationBar(animated: Bool = true)
	{
		UIView.animate(withDuration: animated ? 0.35 : 0.0, delay: 0.0, options: .curveEaseOut, animations: {
			self.searchView.y = 0.0
		}, completion:{ finished in
			self.searchBarVisible = true
			self.searchBar.becomeFirstResponder()
		})
	}

	fileprivate func updateNavigationTitle()
	{
		let p = NSMutableParagraphStyle()
		p.alignment = .center
		p.lineBreakMode = .byWordWrapping
		var title = ""
		switch _displayType
		{
			case .albums:
				let n = MusicDataSource.shared.albums.count
				title = "\(n) \(n == 1 ? NYXLocalizedString("lbl_album") : NYXLocalizedString("lbl_albums"))"
			case .genres:
				let n = MusicDataSource.shared.genres.count
				title = "\(n) \(n == 1 ? NYXLocalizedString("lbl_genre") : NYXLocalizedString("lbl_genres"))"
			case .artists:
				let n = MusicDataSource.shared.artists.count
				title = "\(n) \(n == 1 ? NYXLocalizedString("lbl_artist") : NYXLocalizedString("lbl_artists"))"
			case .playlists:
				let n = MusicDataSource.shared.playlists.count
				title = "\(n) \(n == 1 ? NYXLocalizedString("lbl_playlist") : NYXLocalizedString("lbl_playlists"))"
		}
		let astr1 = NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName : #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1), NSFontAttributeName : UIFont(name: "HelveticaNeue-Medium", size: 14.0)!, NSParagraphStyleAttributeName : p])
		titleView.setAttributedTitle(astr1, for: .normal)
		let astr2 = NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName : #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 1), NSFontAttributeName : UIFont(name: "HelveticaNeue-Medium", size: 14.0)!, NSParagraphStyleAttributeName : p])
		titleView.setAttributedTitle(astr2, for: .highlighted)
	}

	fileprivate func downloadCoverForAlbum(_ album: Album, cropSize: CGSize, callback:((_ cover: UIImage, _ thumbnail: UIImage) -> Void)?)
	{
		let downloadOperation = CoverOperation(album: album, cropSize: cropSize)
		let key = album.uniqueIdentifier
		weak var weakOperation = downloadOperation
		downloadOperation.callback = {(cover: UIImage, thumbnail: UIImage) in
			if let op = weakOperation
			{
				if !op.isCancelled
				{
					self._downloadOperations.removeValue(forKey: key)
				}
			}
			if let block = callback
			{
				block(cover, thumbnail)
			}
		}
		_downloadOperations[key] = downloadOperation
		APP_DELEGATE().operationQueue.addOperation(downloadOperation)
	}

	// MARK: - Notifications
	func audioServerConfigurationDidChange(_ aNotification: Notification)
	{
		_serverChanged = true
	}

	func miniPlayShouldExpandNotification(_ aNotification: Notification)
	{
		self.navigationController?.performSegue(withIdentifier: "root-to-player", sender: self.navigationController)
	}
}

// MARK: - UICollectionViewDataSource
extension RootVC : UICollectionViewDataSource
{
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		if searching
		{
			return searchResults.count
		}

		switch _displayType
		{
			case .albums:
				return MusicDataSource.shared.albums.count
			case .genres:
				return MusicDataSource.shared.genres.count
			case .artists:
				return MusicDataSource.shared.artists.count
			case .playlists:
				return MusicDataSource.shared.playlists.count
		}
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
	{
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "io.whine.mpdremote.cell.album", for: indexPath) as! RootCollectionViewCell
		cell.layer.shouldRasterize = true
		cell.layer.rasterizationScale = UIScreen.main.scale
		cell.label.textColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
		cell.label.backgroundColor = collectionView.backgroundColor

		// Sanity check
		if searching && indexPath.row >= searchResults.count
		{
			return cell
		}

		switch _displayType
		{
			case .albums:
				let album = searching ? searchResults[indexPath.row] as! Album : MusicDataSource.shared.albums[indexPath.row]
				_configureCellForAlbum(cell, indexPath: indexPath, album: album)
			case .genres:
				let genre = searching ? searchResults[indexPath.row] as! Genre : MusicDataSource.shared.genres[indexPath.row]
				_configureCellForGenre(cell, indexPath: indexPath, genre: genre)
			case .artists:
				let artist = searching ? searchResults[indexPath.row] as! Artist : MusicDataSource.shared.artists[indexPath.row]
				_configureCellForArtist(cell, indexPath: indexPath, artist: artist)
			case .playlists:
				let playlist = searching ? searchResults[indexPath.row] as! Playlist : MusicDataSource.shared.playlists[indexPath.row]
				_configureCellForPlaylist(cell, indexPath: indexPath, playlist: playlist)
		}

		return cell
	}

	private func _configureCellForAlbum(_ cell: RootCollectionViewCell, indexPath: IndexPath, album: Album)
	{
		// Set title
		cell.label.text = album.name
		cell.accessibilityLabel = album.name

		// If image is in cache, bail out quickly
		if let cachedImage = ImageCache.shared[album.uniqueIdentifier]
		{
			cell.image = cachedImage
			return
		}
		cell.image = nil

		// Get local URL for cover
		guard let coverURL = album.localCoverURL else
		{
			Logger.alog("[!] No cover file URL for \(album)") // should not happen
			cell.image = nil
			return
		}

		if let cover = UIImage.loadFromFileURL(coverURL)
		{
			cell.image = cover
			ImageCache.shared[album.uniqueIdentifier] = cover
		}
		else
		{
			if album.path != nil
			{
				downloadCoverForAlbum(album, cropSize: cell.imageView.size) { (cover: UIImage, thumbnail: UIImage) in
					DispatchQueue.main.async {
						if let c = self.collectionView.cellForItem(at: indexPath) as? RootCollectionViewCell
						{
							c.image = thumbnail
						}
					}
				}
			}
			else
			{
				MusicDataSource.shared.getPathForAlbum(album) {
					self.downloadCoverForAlbum(album, cropSize: cell.imageView.size) { (cover: UIImage, thumbnail: UIImage) in
						DispatchQueue.main.async {
							if let c = self.collectionView.cellForItem(at: indexPath) as? RootCollectionViewCell
							{
								c.image = thumbnail
							}
						}
					}
				}
			}
		}
	}

	private func _configureCellForGenre(_ cell: RootCollectionViewCell, indexPath: IndexPath, genre: Genre)
	{
		cell.label.text = genre.name
		cell.accessibilityLabel = genre.name

		if let album = genre.albums.first
		{
			// If image is in cache, bail out quickly
			if let cachedImage = ImageCache.shared[album.uniqueIdentifier]
			{
				cell.image = cachedImage
				return
			}
			cell.image = nil

			// Get local URL for cover
			guard let coverURL = album.localCoverURL else
			{
				Logger.alog("[!] No cover URL for \(album)") // should not happen
				cell.image = nil
				return
			}

			if let cover = UIImage.loadFromFileURL(coverURL)
			{
				cell.image = cover
				ImageCache.shared[album.uniqueIdentifier] = cover
			}
			else
			{
				if album.path != nil
				{
					downloadCoverForAlbum(album, cropSize: cell.imageView.size) { (cover: UIImage, thumbnail: UIImage) in
						DispatchQueue.main.async {
							if let c = self.collectionView.cellForItem(at: indexPath) as? RootCollectionViewCell
							{
								c.image = thumbnail
							}
						}
					}
				}
				else
				{
					MusicDataSource.shared.getPathForAlbum(album) {
						self.downloadCoverForAlbum(album, cropSize: cell.imageView.size) { (cover: UIImage, thumbnail: UIImage) in
							DispatchQueue.main.async {
								if let c = self.collectionView.cellForItem(at: indexPath) as? RootCollectionViewCell
								{
									c.image = thumbnail
								}
							}
						}
					}
				}
			}
		}
		else
		{
			cell.image = nil
			MusicDataSource.shared.getAlbumForGenre(genre) {
				DispatchQueue.main.async {
					if let _ = self.collectionView.cellForItem(at: indexPath) as? RootCollectionViewCell
					{
						self.collectionView.reloadItems(at: [indexPath])
					}
				}
			}
			return
		}
	}

	private func _configureCellForArtist(_ cell: RootCollectionViewCell, indexPath: IndexPath, artist: Artist)
	{
		cell.label.text = artist.name
		cell.accessibilityLabel = artist.name

		if artist.albums.count > 0
		{
			if let album = artist.albums.first
			{
				// If image is in cache, bail out quickly
				if let cachedImage = ImageCache.shared[album.uniqueIdentifier]
				{
					cell.image = cachedImage
					return
				}
				cell.image = nil

				// Get local URL for cover
				guard let coverURL = album.localCoverURL else
				{
					Logger.alog("[!] No cover URL for \(album)") // should not happen
					cell.image = nil
					return
				}

				if let cover = UIImage.loadFromFileURL(coverURL)
				{
					cell.image = cover
					ImageCache.shared[album.uniqueIdentifier] = cover
				}
				else
				{
					let sizeAsData = UserDefaults.standard.data(forKey: kNYXPrefCoversSize)!
					let cropSize = NSKeyedUnarchiver.unarchiveObject(with: sizeAsData) as! NSValue
					if album.path != nil
					{
						downloadCoverForAlbum(album, cropSize: cropSize.cgSizeValue) { (cover: UIImage, thumbnail: UIImage) in
							let cropped = thumbnail.smartCropped(toSize: cell.imageView.size)
							DispatchQueue.main.async {
								if let c = self.collectionView.cellForItem(at: indexPath) as? RootCollectionViewCell
								{
									c.image = cropped
								}
							}
						}
					}
					else
					{
						MusicDataSource.shared.getPathForAlbum(album) {
							self.downloadCoverForAlbum(album, cropSize: cropSize.cgSizeValue) { (cover: UIImage, thumbnail: UIImage) in
								let cropped = thumbnail.smartCropped(toSize: cell.imageView.size)
								DispatchQueue.main.async {
									if let c = self.collectionView.cellForItem(at: indexPath) as? RootCollectionViewCell
									{
										c.image = cropped
									}
								}
							}
						}
					}
				}
			}
		}
		else
		{
			cell.image = nil
			MusicDataSource.shared.getAlbumsForArtist(artist) {
				DispatchQueue.main.async {
					if let _ = self.collectionView.cellForItem(at: indexPath) as? RootCollectionViewCell
					{
						self.collectionView.reloadItems(at: [indexPath])
					}
				}
			}
		}
	}

	private func _configureCellForPlaylist(_ cell: RootCollectionViewCell, indexPath: IndexPath, playlist: Playlist)
	{
		cell.label.text = playlist.name
		cell.accessibilityLabel = playlist.name
		cell.image = generateCoverForPlaylist(playlist, size: cell.imageView.size)
	}
}

// MARK: - UICollectionViewDelegate
extension RootVC : UICollectionViewDelegate
{
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
	{
		// If menu is visible ignore default behavior and hide it
		if menuView.visible
		{
			collectionView.deselectItem(at: indexPath, animated: false)
			showLeftViewAction(nil)
			return
		}

		// Hide the searchbar
		/*if searchBarVisible
		{
			showNavigationBar(animated:true)
		}*/

		switch _displayType
		{
			case .albums:
				performSegue(withIdentifier: "root-albums-to-detail-album", sender: self)
			case .genres:
				performSegue(withIdentifier: "root-genres-to-artists", sender: self)
			case .artists:
				performSegue(withIdentifier: "root-artists-to-albums", sender: self)
			case .playlists:
				performSegue(withIdentifier: "root-playlists-to-detail-playlist", sender: self)
		}
	}

	func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
	{
		if _displayType != .albums
		{
			return
		}

		// When searching things can go wrong, this prevent some crashes
		let src = searching ? searchResults as! [Album] : MusicDataSource.shared.albums
		if indexPath.row >= src.count
		{
			return
		}

		// Remove download cover operation if still in queue
		let album = src[indexPath.row]
		let key = album.uniqueIdentifier
		if let op = _downloadOperations[key] as! CoverOperation?
		{
			_downloadOperations.removeValue(forKey: key)
			op.cancel()
			Logger.dlog("[+] Cancelling \(op)")
		}
	}
}

// MARK: - UIScrollViewDelegate
extension RootVC : UIScrollViewDelegate
{
	func scrollViewDidScroll(_ scrollView: UIScrollView)
	{
		if searchBarVisible
		{
			if scrollView.contentOffset.y > 0.0
			{
				showNavigationBar(animated: true)
			}
			return
		}

		if scrollView.contentOffset.y < -scrollView.contentInset.top
		{
			if scrollView.contentOffset.y < -(searchView.height + scrollView.contentInset.top)
			{
				searchView.y = 0.0
			}
			else
			{
				searchView.y = -searchView.height + (fabs(scrollView.contentOffset.y) - scrollView.contentInset.top)
			}
		}
		else
		{
			searchView.y = -searchView.height
		}
	}

	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
	{
		if scrollView.contentOffset.y <= -(searchView.height + scrollView.contentInset.top)
		{
			searchBarVisible = true
			searchBar.becomeFirstResponder()
		}
		else
		{
			searchBarVisible = false
		}
	}
}

// MARK: - UISearchBarDelegate
extension RootVC : UISearchBarDelegate
{
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
	{
		searchResults.removeAll()
		searching = false
		searchBar.text = ""
		searchBar.resignFirstResponder()
		showNavigationBar(animated: true)
		//searchBarVisible = false
		collectionView.reloadData()
	}

	func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
	{
		collectionView.reloadData()
		searchBar.endEditing(true)
	}

	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
	{
		searching = true
		// Copy original source to avoid crash when nothing was searched
		switch _displayType
		{
			case .albums:
				searchResults = MusicDataSource.shared.albums
			case .genres:
				searchResults = MusicDataSource.shared.genres
			case .artists:
				searchResults = MusicDataSource.shared.artists
			case .playlists:
				searchResults = MusicDataSource.shared.playlists
		}
	}

	func searchBarTextDidEndEditing(_ searchBar: UISearchBar)
	{
		//searching = false
		//searchResults.removeAll()
	}

	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
	{
		switch _displayType
		{
			case .albums:
				if MusicDataSource.shared.albums.count > 0
				{
					searchResults = MusicDataSource.shared.albums.filter({$0.name.fuzzySearch(withString: searchText)})
				}
			case .genres:
				if MusicDataSource.shared.genres.count > 0
				{
					searchResults = MusicDataSource.shared.genres.filter({$0.name.fuzzySearch(withString: searchText)})
				}
			case .artists:
				if MusicDataSource.shared.artists.count > 0
				{
					searchResults = MusicDataSource.shared.artists.filter({$0.name.fuzzySearch(withString: searchText)})
				}
			case .playlists:
				if MusicDataSource.shared.playlists.count > 0
				{
					searchResults = MusicDataSource.shared.playlists.filter({$0.name.fuzzySearch(withString: searchText)})
				}
		}
		collectionView.reloadData()
	}
}

// MARK: - TypeChoiceViewDelegate
extension RootVC : TypeChoiceViewDelegate
{
	func didSelectType(_ type: DisplayType)
	{
		// Ignore if type did not change
		if _displayType == type
		{
			changeTypeAction(nil)
			return
		}
		_displayType = type

		UserDefaults.standard.set(type.rawValue, forKey: kNYXPrefDisplayType)
		UserDefaults.standard.synchronize()

		// Refresh view
		MusicDataSource.shared.getListForDisplayType(type) {
			DispatchQueue.main.async {
				self.collectionView.reloadData()
				self.changeTypeAction(nil)
				if MusicDataSource.shared.currentCollection(type).count == 0
				{
					self.collectionView.contentOffset = CGPoint(0, 64)
				}
				else
				{
					self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false) // Scroll to top
				}
				self.updateNavigationTitle()
			}
		}
	}
}

// MARK: - UIResponder
extension RootVC
{
	override var canBecomeFirstResponder: Bool
	{
		return true
	}

	override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?)
	{
		if UserDefaults.standard.bool(forKey: kNYXPrefShakeToPlayRandomAlbum) == false
		{
			return
		}
		
		if motion == .motionShake
		{
			let randomAlbum = MusicDataSource.shared.albums.randomItem()
			if randomAlbum.tracks == nil
			{
				MusicDataSource.shared.getTracksForAlbum(randomAlbum) {
					PlayerController.shared.playAlbum(randomAlbum, shuffle: false, loop: false)
				}
			}
			else
			{
				PlayerController.shared.playAlbum(randomAlbum, shuffle: false, loop: false)
			}

			// Briefly display cover of album
			let sizeAsData = UserDefaults.standard.data(forKey: kNYXPrefCoversSize)!
			let cropSize = NSKeyedUnarchiver.unarchiveObject(with: sizeAsData) as! NSValue
			MusicDataSource.shared.getPathForAlbum(randomAlbum) {
				self.downloadCoverForAlbum(randomAlbum, cropSize: cropSize.cgSizeValue, callback: { (cover: UIImage, thumbnail: UIImage) in
					let size = CGSize(self.view.width - 64.0, self.view.width - 64.0)
					let cropped = cover.smartCropped(toSize: size)
					DispatchQueue.main.async {
						let iv = UIImageView(frame: CGRect((self.view.width - 64.0) * 0.5, (self.view.height - 64.0) * 0.5, 64.0, 64.0))
						iv.image = cropped
						iv.alpha = 0.0
						self.view.addSubview(iv)
						UIView.animate(withDuration: 1.0, delay: 0.0, options: .curveEaseIn, animations: {
							iv.frame = CGRect((self.view.width - size.width) * 0.5, (self.view.height - size.height) * 0.5, size)
							iv.alpha = 1.0
						}, completion:{ finished in
							iv.removeFromSuperview()
						})
					}
				})
			}
		}
	}
}

// MARK: - UIViewControllerTransitioningDelegate
extension NYXNavigationController : UIViewControllerTransitioningDelegate
{
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning?
	{
		let c = PlayerVCCustomPresentAnimationController()
		c.presenting = true
		return c
	}

	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
	{
		let c = PlayerVCCustomPresentAnimationController()
		c.presenting = false
		return c
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
		if segue.identifier == "root-to-player"
		{
			let vc = segue.destination as! PlayerVC
			vc.transitioningDelegate = self
			vc.modalPresentationStyle = .custom
		}
	}
}
