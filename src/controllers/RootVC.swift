// RootVC.swift
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


private let __sideSpan = CGFloat(10.0)
private let __columns = 3
private let __insets = UIEdgeInsets(top:__sideSpan, left:__sideSpan, bottom:__sideSpan, right:__sideSpan)


final class RootVC : MenuVC
{
	// MARK: - Private properties
	// Albums view
	@IBOutlet var collectionView: UICollectionView!
	// Top constraint for collection view
	@IBOutlet var topConstraint: NSLayoutConstraint!
	// Search bar
	var searchBar: UISearchBar! = nil
	// Button in the navigationbar
	var titleView: UIButton! = nil
	// Random button
	var btnRandom: UIButton! = nil
	// Repeat button
	var btnRepeat: UIButton! = nil
	// Should show the search view, flag
	var searchBarVisible = false
	// Is currently searching, flag
	var searching = false
	// Search results
	var searchResults = [AnyObject]()
	// Long press gesture is recognized, flag
	var longPressRecognized = false
	// Keep track of download operations to eventually cancel them
	var _downloadOperations = [String : Operation]()
	// View to change the type of items in the collection view
	var _typeChoiceView: TypeChoiceView! = nil
	// Active display type
	var _displayType = DisplayType(rawValue:UserDefaults.standard.integer(forKey: kNYXPrefDisplayType))!

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Remove back button label
		navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)

		// Customize navbar
		let headerColor = #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)
		let navigationBar = (navigationController?.navigationBar)!

		// Searchbar
		let searchView = UIView(frame:CGRect(0.0, 0.0, navigationBar.width, 64.0))
		searchView.backgroundColor = navigationBar.barTintColor
		navigationController?.view.insertSubview(searchView, belowSubview:navigationBar)
		searchBar = UISearchBar(frame:navigationBar.frame)
		searchBar.searchBarStyle = .minimal
		searchBar.barTintColor = searchView.backgroundColor
		searchBar.tintColor = navigationBar.tintColor
		(searchBar.value(forKey: "searchField") as? UITextField)?.textColor = headerColor
		searchBar.showsCancelButton = true
		searchBar.delegate = self
		searchView.addSubview(searchBar)

		// Navigation bar title
		titleView = UIButton(frame:CGRect(0.0, 0.0, 100.0, navigationBar.height))
		titleView.addTarget(self, action:#selector(changeTypeAction(_:)), for:.touchUpInside)
		navigationItem.titleView = titleView

		// Random button
		let random = UserDefaults.standard.bool(forKey: kNYXPrefRandom)
		let imageRandom = #imageLiteral(resourceName: "btn-random")
		btnRandom = UIButton(type:.custom)
		btnRandom.frame = CGRect((navigationController?.navigationBar.frame.width)! - 44.0, 0.0, 44.0, 44.0)
		btnRandom.setImage(imageRandom.imageTintedWithColor(UIColor.fromRGB(0xCC0000))?.withRenderingMode(.alwaysOriginal), for:UIControlState())
		btnRandom.setImage(imageRandom.imageTintedWithColor(#colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1))?.withRenderingMode(.alwaysOriginal), for:.selected)
		btnRandom.isSelected = random
		btnRandom.addTarget(self, action:#selector(toggleRandomAction(_:)), for:.touchUpInside)
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")
		navigationController?.navigationBar.addSubview(btnRandom)

		// Repeat button
		let loop = UserDefaults.standard.bool(forKey: kNYXPrefRepeat)
		let imageRepeat = #imageLiteral(resourceName: "btn-repeat")
		btnRepeat = UIButton(type:.custom)
		btnRepeat.frame = CGRect((navigationController?.navigationBar.frame.width)! - 88.0, 0.0, 44.0, 44.0)
		btnRepeat.setImage(imageRepeat.imageTintedWithColor(UIColor.fromRGB(0xCC0000))?.withRenderingMode(.alwaysOriginal), for:UIControlState())
		btnRepeat.setImage(imageRepeat.imageTintedWithColor(#colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1))?.withRenderingMode(.alwaysOriginal), for:.selected)
		btnRepeat.isSelected = loop
		btnRepeat.addTarget(self, action:#selector(toggleRepeatAction(_:)), for:.touchUpInside)
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")
		navigationController?.navigationBar.addSubview(btnRepeat)

		// Create collection view
		collectionView.register(RootCollectionViewCell.classForCoder(), forCellWithReuseIdentifier:"io.whine.mpdremote.cell.album")
		(collectionView.collectionViewLayout as! UICollectionViewFlowLayout).sectionInset = __insets;
		let w = ceil((/*collectionView.width*/UIScreen.main.bounds.width / CGFloat(__columns)) - (2 * __sideSpan))
		(collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize = CGSize(w, w + 20.0);

		// Longpress
		let longPress = UILongPressGestureRecognizer(target:self, action:#selector(longPress(_:)))
		longPress.minimumPressDuration = 0.5
		longPress.delaysTouchesBegan = true
		collectionView.addGestureRecognizer(longPress)

		// Double tap
		let doubleTap = UITapGestureRecognizer(target:self, action:#selector(doubleTap(_:)))
		doubleTap.numberOfTapsRequired = 2
		doubleTap.numberOfTouchesRequired = 1
		doubleTap.delaysTouchesBegan = true
		collectionView.addGestureRecognizer(doubleTap)

		_ = MiniPlayerView.shared.visible
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		// Initialize the mpd connection
		if MPDDataSource.shared.server == nil
		{
			if let serverAsData = UserDefaults.standard.data(forKey: kNYXPrefMPDServer)
			{
				if let server = NSKeyedUnarchiver.unarchiveObject(with: serverAsData) as! MPDServer?
				{
					// Data source
					MPDDataSource.shared.server = server
					_ = MPDDataSource.shared.initialize()
					if _displayType != .albums
					{
						// Always fetch the albums list
						MPDDataSource.shared.getListForDisplayType(.albums) {}
					}
					MPDDataSource.shared.getListForDisplayType(_displayType) {
						DispatchQueue.main.async {
							self.collectionView.reloadData()
							self._updateNavigationTitle()
						}
					}

					// Player
					MPDPlayer.shared.server = server
					_ = MPDPlayer.shared.initialize()
				}
				else
				{
					let alertController = UIAlertController(title:NYXLocalizedString("lbl_alert_servercfg_error"), message:NYXLocalizedString("lbl_alert_server_need_check"), preferredStyle:.alert)
					let cancelAction = UIAlertAction(title:NYXLocalizedString("lbl_ok"), style:.cancel, handler:nil)
					alertController.addAction(cancelAction)
					present(alertController, animated:true, completion:nil)
				}
			}
			else
			{
				/*Logger.alog("[+] No MPD server registered yet.")
				let serverVC = APP_DELEGATE().serverVC
				APP_DELEGATE().window?.rootViewController = serverVC*/
				let server = MPDServer.def()
				MPDDataSource.shared.server = server
				_ = MPDDataSource.shared.initialize()
				if _displayType != .albums
				{
					// Always fetch the albums list
					MPDDataSource.shared.getListForDisplayType(.albums) {}
				}
				MPDDataSource.shared.getListForDisplayType(_displayType) {
					DispatchQueue.main.async {
						self.collectionView.reloadData()
						self._updateNavigationTitle()
					}
				}

				// Player
				MPDPlayer.shared.server = server
				_ = MPDPlayer.shared.initialize()
			}
		}

		// Since we are in search mode, show the bar
		if searching
		{
			_hideNavigationBar(animated:true)
		}

		// Deselect cell
		if let idxs = collectionView.indexPathsForSelectedItems
		{
			for indexPath in idxs
			{
				collectionView.deselectItem(at: indexPath, animated:true)
			}
		}
	}

	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)

		APP_DELEGATE().operationQueue.cancelAllOperations()
		_downloadOperations.removeAll()
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return .portrait
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .lightContent
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
		if segue.identifier == "root-albums-to-detail-album"
		{
			let vc = segue.destination as! AlbumDetailVC
			vc.albums = searching ? searchResults as! [Album] : MPDDataSource.shared.albums
			vc.selectedIndex = collectionView.indexPathsForSelectedItems![0].row
		}
		else if segue.identifier == "root-genres-to-artists"
		{
			let row = collectionView.indexPathsForSelectedItems![0].row
			let genre = searching ? searchResults[row] as! Genre : MPDDataSource.shared.genres[row]
			let vc = segue.destination as! ArtistsVC
			vc.genre = genre
		}
		else if segue.identifier == "root-artists-to-albums"
		{
			let row = collectionView.indexPathsForSelectedItems![0].row
			let artist = searching ? searchResults[row] as! Artist : MPDDataSource.shared.artists[row]
			let vc = segue.destination as! AlbumsVC
			vc.artist = artist
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
					let album = searching ? searchResults[indexPath.row] as! Album : MPDDataSource.shared.albums[indexPath.row]
					MPDPlayer.shared.playAlbum(album, random:UserDefaults.standard.bool(forKey: kNYXPrefRandom), loop:UserDefaults.standard.bool(forKey: kNYXPrefRepeat))
				case .artists:
					let artist = searching ? searchResults[indexPath.row] as! Artist : MPDDataSource.shared.artists[indexPath.row]
					MPDDataSource.shared.getAlbumsForArtist(artist) {
						MPDDataSource.shared.getSongsForAlbums(artist.albums) {
							let ar = artist.albums.flatMap({$0.songs}).flatMap({$0})
							MPDPlayer.shared.playTracks(ar, random:UserDefaults.standard.bool(forKey: kNYXPrefRandom), loop:UserDefaults.standard.bool(forKey: kNYXPrefRepeat))
						}
					}
				case .genres:
					let genre = searching ? searchResults[indexPath.row] as! Genre : MPDDataSource.shared.genres[indexPath.row]
					MPDDataSource.shared.getAlbumsForGenre(genre) {
						MPDDataSource.shared.getSongsForAlbums(genre.albums) {
							let ar = genre.albums.flatMap({$0.songs}).flatMap({$0})
							MPDPlayer.shared.playTracks(ar, random:UserDefaults.standard.bool(forKey: kNYXPrefRandom), loop:UserDefaults.standard.bool(forKey: kNYXPrefRepeat))
						}
					}
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

			let alertController = UIAlertController(title:nil, message:nil, preferredStyle:.actionSheet)
			let cancelAction = UIAlertAction(title:NYXLocalizedString("lbl_cancel"), style:.cancel) { (action) in
				self.longPressRecognized = false
				cell.longPressed = false
				MiniPlayerView.shared.stayHidden = false
			}
			alertController.addAction(cancelAction)

			switch _displayType
			{
				case .albums:
					let album = searching ? searchResults[indexPath.row] as! Album : MPDDataSource.shared.albums[indexPath.row]
					let playAction = UIAlertAction(title:NYXLocalizedString("lbl_play"), style:.default) { (action) in
						MPDPlayer.shared.playAlbum(album, random:false, loop:false)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_shuffle"), style:.default) { (action) in
						MPDPlayer.shared.playAlbum(album, random:true, loop:false)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_addqueue"), style:.default) { (action) in
						MPDPlayer.shared.addAlbumToQueue(album)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(addQueueAction)
				case .artists:
					let artist = searching ? searchResults[indexPath.row] as! Artist : MPDDataSource.shared.artists[indexPath.row]
					let playAction = UIAlertAction(title:NYXLocalizedString("lbl_play"), style:.default) { (action) in
						MPDDataSource.shared.getAlbumsForArtist(artist) {
							MPDDataSource.shared.getSongsForAlbums(artist.albums) {
								let ar = artist.albums.flatMap({$0.songs}).flatMap({$0})
								MPDPlayer.shared.playTracks(ar, random:false, loop:false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_shuffle"), style:.default) { (action) in
						MPDDataSource.shared.getAlbumsForArtist(artist) {
							MPDDataSource.shared.getSongsForAlbums(artist.albums) {
								let ar = artist.albums.flatMap({$0.songs}).flatMap({$0})
								MPDPlayer.shared.playTracks(ar, random:true, loop:false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_addqueue"), style:.default) { (action) in
						MPDDataSource.shared.getAlbumsForArtist(artist) {
							for album in artist.albums
							{
								MPDPlayer.shared.addAlbumToQueue(album)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(addQueueAction)
				case .genres:
					let genre = self.searching ? self.searchResults[indexPath.row] as! Genre : MPDDataSource.shared.genres[indexPath.row]
					let playAction = UIAlertAction(title:NYXLocalizedString("lbl_play"), style:.default) { (action) in
						MPDDataSource.shared.getAlbumsForGenre(genre) {
							MPDDataSource.shared.getSongsForAlbums(genre.albums) {
								let ar = genre.albums.flatMap({$0.songs}).flatMap({$0})
								MPDPlayer.shared.playTracks(ar, random:false, loop:false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_shuffle"), style:.default) { (action) in
						MPDDataSource.shared.getAlbumsForGenre(genre) {
							MPDDataSource.shared.getSongsForAlbums(genre.albums) {
								let ar = genre.albums.flatMap({$0.songs}).flatMap({$0})
								MPDPlayer.shared.playTracks(ar, random:true, loop:false)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_addqueue"), style:.default) { (action) in
						MPDDataSource.shared.getAlbumsForGenre(genre) {
							for album in genre.albums
							{
								MPDPlayer.shared.addAlbumToQueue(album)
							}
						}
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(addQueueAction)
			}

			present(alertController, animated:true, completion:nil)
		}
	}

	// MARK: - Buttons actions
	func changeTypeAction(_ sender: UIButton?)
	{
		if _typeChoiceView == nil
		{
			_typeChoiceView = TypeChoiceView(frame:CGRect(0.0, 0.0, collectionView.width, 132.0))
			_typeChoiceView.delegate = self
		}

		if _typeChoiceView.superview != nil
		{
			view.backgroundColor = UIColor.fromRGB(0xECECEC)
			UIView.animate(withDuration: 0.35, delay:0.0, options:.curveEaseOut, animations:{
				self.topConstraint.constant = 0.0;
				self.collectionView.layoutIfNeeded()
			}, completion:{ finished in
				self._typeChoiceView.removeFromSuperview()
			})
		}
		else
		{
			view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
			_typeChoiceView.tableView.reloadData()
			view.insertSubview(_typeChoiceView, belowSubview:collectionView)
			topConstraint.constant = _typeChoiceView.height;

			UIView.animate(withDuration: 0.35, delay:0.0, options:.curveEaseOut, animations:{
				self.topConstraint.constant = 132.0;
				self.collectionView.layoutIfNeeded()
			}, completion:nil)
		}
	}

	func toggleRandomAction(_ sender: AnyObject?)
	{
		let prefs = UserDefaults.standard
		let random = !prefs.bool(forKey: kNYXPrefRandom)

		btnRandom.isSelected = random
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		prefs.set(random, forKey:kNYXPrefRandom)
		prefs.synchronize()

		MPDPlayer.shared.setRandom(random)
	}

	func toggleRepeatAction(_ sender: AnyObject?)
	{
		let prefs = UserDefaults.standard
		let loop = !prefs.bool(forKey: kNYXPrefRepeat)

		btnRepeat.isSelected = loop
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

		prefs.set(loop, forKey:kNYXPrefRepeat)
		prefs.synchronize()

		MPDPlayer.shared.setRepeat(loop)
	}

	// MARK: - Private
	func _showNavigationBar(animated: Bool = true)
	{
		searchBar.endEditing(true)
		let bar = (navigationController?.navigationBar)!
		UIView.animate(withDuration: animated ? 0.35 : 0.0, delay:0.0, options:.curveEaseOut, animations:{
			bar.y = 20.0
		}, completion:{ finished in
			self.searchBarVisible = false
		})
	}

	func _hideNavigationBar(animated: Bool = true)
	{
		let bar = (navigationController?.navigationBar)!
		UIView.animate(withDuration: animated ? 0.35 : 0.0, delay:0.0, options:.curveEaseOut, animations:{
			bar.y = -48.0
		}, completion:{ finished in
			self.searchBarVisible = true
		})
	}

	func _updateNavigationTitle()
	{
		let p = NSMutableParagraphStyle()
		p.alignment = .center
		p.lineBreakMode = .byWordWrapping
		var title = ""
		switch _displayType
		{
			case .albums:
				let n = MPDDataSource.shared.albums.count
				title = "\(n) \(n > 1 ? NYXLocalizedString("lbl_albums") : NYXLocalizedString("lbl_album"))"
			case .genres:
				let n = MPDDataSource.shared.genres.count
				title = "\(n) \(n > 1 ? NYXLocalizedString("lbl_genres") : NYXLocalizedString("lbl_genre"))"
			case .artists:
				let n = MPDDataSource.shared.artists.count
				title = "\(n) \(n > 1 ? NYXLocalizedString("lbl_artists") : NYXLocalizedString("lbl_artist"))"
		}
		let astr1 = NSAttributedString(string:title, attributes:[NSForegroundColorAttributeName : #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1), NSFontAttributeName : UIFont(name:"HelveticaNeue-Medium", size:14.0)!, NSParagraphStyleAttributeName : p])
		titleView.setAttributedTitle(astr1, for:UIControlState())
		let astr2 = NSAttributedString(string:title, attributes:[NSForegroundColorAttributeName : UIColor.fromRGB(0xCC0000), NSFontAttributeName : UIFont(name:"HelveticaNeue-Medium", size:14.0)!, NSParagraphStyleAttributeName : p])
		titleView.setAttributedTitle(astr2, for:.highlighted)
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
				return MPDDataSource.shared.albums.count
			case .genres:
				return MPDDataSource.shared.genres.count
			case .artists:
				return MPDDataSource.shared.artists.count
		}
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
	{
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "io.whine.mpdremote.cell.album", for:indexPath) as! RootCollectionViewCell
		cell.layer.shouldRasterize = true
		cell.layer.rasterizationScale = UIScreen.main.scale

		// Sanity check
		if searching && indexPath.row >= searchResults.count
		{
			return cell
		}

		switch _displayType
		{
			case .albums:
				let album = searching ? searchResults[indexPath.row] as! Album : MPDDataSource.shared.albums[indexPath.row]
				_configureCellForAlbum(cell, indexPath:indexPath, album:album)
			case .genres:
				let genre = searching ? searchResults[indexPath.row] as! Genre : MPDDataSource.shared.genres[indexPath.row]
				_configureCellForGenre(cell, indexPath:indexPath, genre:genre)
			case .artists:
				let artist = searching ? searchResults[indexPath.row] as! Artist : MPDDataSource.shared.artists[indexPath.row]
				_configureCellForArtist(cell, indexPath:indexPath, artist:artist)
		}

		return cell
	}

	private func _configureCellForAlbum(_ cell: RootCollectionViewCell, indexPath: IndexPath, album: Album)
	{
		// Set title
		cell.label.text = album.name
		cell.accessibilityLabel = album.name

		// If image is in cache, bail out quickly
		if let cachedImage = ImageCache.shared[album.uuid]
		{
			cell.image = cachedImage
			return
		}

		// Get local URL for cover
		guard let coverURL = album.localCoverURL else
		{
			Logger.alog("[!] No cover URL for \(album)") // should not happen
			cell.image = generateCoverForAlbum(album, size: cell.imageView.size)
			return
		}

		if let cover = UIImage.loadFromURL(coverURL)
		{
			cell.image = cover
			ImageCache.shared[album.uuid] = cover
		}
		else
		{
			if album.path != nil
			{
				_downloadCoverForAlbum(album, cropSize:cell.imageView.size) { (cover: UIImage, thumbnail: UIImage) in
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
				MPDDataSource.shared.getPathForAlbum(album) {
					self._downloadCoverForAlbum(album, cropSize:cell.imageView.size) { (cover: UIImage, thumbnail: UIImage) in
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

		if UserDefaults.standard.data(forKey: kNYXPrefWEBServer) == nil
		{
			cell.image = generateCoverForGenre(genre, size: cell.imageView.size)
			return
		}

		if let album = genre.albums.first
		{
			// If image is in cache, bail out quickly
			if let cachedImage = ImageCache.shared[album.uuid]
			{
				cell.image = cachedImage
				return
			}

			// Get local URL for cover
			guard let coverURL = album.localCoverURL else
			{
				Logger.alog("[!] No cover URL for \(album)") // should not happen
				cell.image = generateCoverForGenre(genre, size: cell.imageView.size)
				return
			}

			if let cover = UIImage.loadFromURL(coverURL)
			{
				cell.image = cover
				ImageCache.shared[album.uuid] = cover
			}
			else
			{
				cell.image = generateCoverForGenre(genre, size: cell.imageView.size)
				if album.path != nil
				{
					_downloadCoverForAlbum(album, cropSize:cell.imageView.size) { (cover: UIImage, thumbnail: UIImage) in
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
					MPDDataSource.shared.getPathForAlbum(album) {
						self._downloadCoverForAlbum(album, cropSize:cell.imageView.size) { (cover: UIImage, thumbnail: UIImage) in
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
			MPDDataSource.shared.getAlbumForGenre(genre) {
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

		if UserDefaults.standard.data(forKey: kNYXPrefWEBServer) == nil
		{
			cell.image = generateCoverForArtist(artist, size: cell.imageView.size)
			return
		}

		if artist.albums.count > 0
		{
			if let album = artist.albums.first
			{
				// If image is in cache, bail out quickly
				if let cachedImage = ImageCache.shared[album.uuid]
				{
					cell.image = cachedImage
					return
				}

				// Get local URL for cover
				guard let coverURL = album.localCoverURL else
				{
					Logger.alog("[!] No cover URL for \(album)") // should not happen
					cell.image = generateCoverForArtist(artist, size: cell.imageView.size)
					return
				}

				if let cover = UIImage.loadFromURL(coverURL)
				{
					cell.image = cover
					ImageCache.shared[album.uuid] = cover
				}
				else
				{
					let sizeAsData = UserDefaults.standard.data(forKey: kNYXPrefCoverSize)!
					let cropSize = NSKeyedUnarchiver.unarchiveObject(with: sizeAsData) as! NSValue
					if album.path != nil
					{
						_downloadCoverForAlbum(album, cropSize:cropSize.cgSizeValue) { (cover: UIImage, thumbnail: UIImage) in
							let cropped = thumbnail.imageCroppedToFitSize(cell.imageView.size)
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
						MPDDataSource.shared.getPathForAlbum(album) {
							self._downloadCoverForAlbum(album, cropSize:cropSize.cgSizeValue) { (cover: UIImage, thumbnail: UIImage) in
								let cropped = thumbnail.imageCroppedToFitSize(cell.imageView.size)
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
			MPDDataSource.shared.getAlbumsForArtist(artist) {
				DispatchQueue.main.async {
					if let _ = self.collectionView.cellForItem(at: indexPath) as? RootCollectionViewCell
					{
						self.collectionView.reloadItems(at: [indexPath])
					}
				}
			}
		}
	}

	func _downloadCoverForAlbum(_ album: Album, cropSize: CGSize, callback:@escaping (_ cover: UIImage, _ thumbnail: UIImage) -> Void)
	{
		let downloadOperation = CoverOperation(album:album, cropSize:cropSize)
		let key = album.name + album.year
		weak var weakOperation = downloadOperation
		downloadOperation.cplBlock = {(cover: UIImage, thumbnail: UIImage) in
			if let op = weakOperation
			{
				if !op.isCancelled
				{
					self._downloadOperations.removeValue(forKey: key)
				}
			}
			callback(cover, thumbnail)
		}
		_downloadOperations[key] = downloadOperation
		APP_DELEGATE().operationQueue.addOperation(downloadOperation)
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
			collectionView.deselectItem(at: indexPath, animated:false)
			showLeftViewAction(nil)
			return
		}

		// Hide the searchbar
		if searchBarVisible
		{
			_showNavigationBar(animated:true)
		}

		switch _displayType
		{
			case .albums:
				performSegue(withIdentifier: "root-albums-to-detail-album", sender: self)
			case .genres:
				performSegue(withIdentifier: "root-genres-to-artists", sender: self)
			case .artists:
				performSegue(withIdentifier: "root-artists-to-albums", sender: self)
		}
	}

	func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
	{
		if _displayType != .albums
		{
			return
		}

		// When searching things can go wrong, this prevent some crashes
		let src = searching ? searchResults as! [Album] : MPDDataSource.shared.albums
		if indexPath.row >= src.count
		{
			return
		}

		// Remove download cover operation if still in queue
		let album = src[indexPath.row]
		let key = album.name + album.year
		if let op = _downloadOperations[key] as! CoverOperation?
		{
			op.cancel()
			_downloadOperations.removeValue(forKey: key)
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
				_showNavigationBar(animated:true)
			}
			return
		}
		let bar = (navigationController?.navigationBar)!
		if scrollView.contentOffset.y <= 0.0
		{
			bar.y = 20.0 + scrollView.contentOffset.y
		}
		else
		{
			bar.y = 20.0
		}
	}

	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
	{
		if scrollView.contentOffset.y <= -44.0
		{
			searchBarVisible = true
			let bar = (navigationController?.navigationBar)!
			bar.y = -48.0
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
		_showNavigationBar(animated:true)
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
				if MPDDataSource.shared.albums.count > 0
				{
					searchResults = MPDDataSource.shared.albums.filter({$0.name.lowercased().contains(searchText.lowercased())})
				}
			case .genres:
				if MPDDataSource.shared.genres.count > 0
				{
					searchResults = MPDDataSource.shared.genres.filter({$0.name.lowercased().contains(searchText.lowercased())})
				}
			case .artists:
				if MPDDataSource.shared.artists.count > 0
				{
					searchResults = MPDDataSource.shared.artists.filter({$0.name.lowercased().contains(searchText.lowercased())})
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
		changeTypeAction(nil)
		if _displayType == type
		{
			return
		}
		_displayType = type

		UserDefaults.standard.set(type.rawValue, forKey:kNYXPrefDisplayType)
		UserDefaults.standard.synchronize()

		// Refresh view
		MPDDataSource.shared.getListForDisplayType(type) {
			DispatchQueue.main.async {
				self.collectionView.setContentOffset(CGPoint.zero, animated:true)
				self.collectionView.reloadData()
				self._updateNavigationTitle()
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
		if motion == .motionShake
		{
			let randomAlbum = MPDDataSource.shared.albums.randomItem()
			if randomAlbum.songs == nil
			{
				MPDDataSource.shared.getSongsForAlbum(randomAlbum) {
					MPDPlayer.shared.playAlbum(randomAlbum, random:false, loop:false)
				}
			}
			else
			{
				MPDPlayer.shared.playAlbum(randomAlbum, random:false, loop:false)
			}

			// Briefly display cover of album
			let sizeAsData = UserDefaults.standard.data(forKey: kNYXPrefCoverSize)!
			let cropSize = NSKeyedUnarchiver.unarchiveObject(with: sizeAsData) as! NSValue
			MPDDataSource.shared.getPathForAlbum(randomAlbum) {
				self._downloadCoverForAlbum(randomAlbum, cropSize:cropSize.cgSizeValue, callback:{ (cover: UIImage, thumbnail: UIImage) in
					let size = CGSize(self.view.width - 64.0, self.view.width - 64.0)
					let cropped = cover.imageCroppedToFitSize(size)
					DispatchQueue.main.async {
						let iv = UIImageView(frame:CGRect((self.view.width - 64.0) * 0.5, (self.view.height - 64.0) * 0.5, 64.0, 64.0))
						iv.image = cropped
						iv.alpha = 0.0
						self.view.addSubview(iv)
						UIView.animate(withDuration: 1.0, delay:0.0, options:.curveEaseIn, animations:{
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
