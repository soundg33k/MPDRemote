// RootVC.swift
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


private let __sideSpan = CGFloat(10.0)
private let __columns = 3
private let __insets = UIEdgeInsets(top:__sideSpan, left:__sideSpan, bottom:__sideSpan, right:__sideSpan)


final class RootVC : MenuVC
{
	// MARK: - Private properties
	// Albums view
	@IBOutlet private var collectionView: UICollectionView!
	// Top constraint for collection view
	@IBOutlet private var topConstraint: NSLayoutConstraint!
	// Search bar
	private var searchBar: UISearchBar! = nil
	// Button in the navigationbar
	private var titleView: UIButton! = nil
	// Random button
	private var btnRandom: UIButton! = nil
	// Repeat button
	private var btnRepeat: UIButton! = nil
	// Should show the search view, flag
	private var searchBarVisible = false
	// Is currently searching, flag
	private var searching = false
	// Search results
	private var searchResults = [AnyObject]()
	// Long press gesture is recognized, flag
	private var longPressRecognized = false
	// Keep track of download operations to eventually cancel them
	private var _downloadOperations = [String : NSOperation]()
	// View to change the type of items in the collection view
	private var _typeChoiceView: TypeChoiceView! = nil
	// Active display type
	private var _displayType = DisplayType(rawValue:NSUserDefaults.standardUserDefaults().integerForKey(kNYXPrefDisplayType))!

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Remove back button label
		navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)

		// Customize navbar
		let headerColor = UIColor.whiteColor()
		let navigationBar = (navigationController?.navigationBar)!

		// Searchbar
		let searchView = UIView(frame:CGRect(0.0, 0.0, navigationBar.width, 64.0))
		searchView.backgroundColor = navigationBar.barTintColor
		navigationController?.view.insertSubview(searchView, belowSubview:navigationBar)
		searchBar = UISearchBar(frame:navigationBar.frame)
		searchBar.searchBarStyle = .Minimal
		searchBar.barTintColor = searchView.backgroundColor
		searchBar.tintColor = navigationBar.tintColor
		(searchBar.valueForKey("searchField") as? UITextField)?.textColor = headerColor
		searchBar.showsCancelButton = true
		searchBar.delegate = self
		searchView.addSubview(searchBar)

		// Navigation bar title
		titleView = UIButton(frame:CGRect(0.0, 0.0, 100.0, navigationBar.height))
		titleView.addTarget(self, action:#selector(changeTypeAction(_:)), forControlEvents:.TouchUpInside)
		navigationItem.titleView = titleView

		// Random button
		let random = NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRandom)
		let imageRandom = UIImage(named:"btn-random")
		btnRandom = UIButton(type:.Custom)
		btnRandom.frame = CGRect((navigationController?.navigationBar.frame.width)! - 44.0, 0.0, 44.0, 44.0)
		btnRandom.setImage(imageRandom?.imageTintedWithColor(UIColor.fromRGB(0xCC0000))?.imageWithRenderingMode(.AlwaysOriginal), forState:.Normal)
		btnRandom.setImage(imageRandom?.imageTintedWithColor(UIColor.whiteColor())?.imageWithRenderingMode(.AlwaysOriginal), forState:.Selected)
		btnRandom.selected = random
		btnRandom.addTarget(self, action:#selector(toggleRandomAction(_:)), forControlEvents:.TouchUpInside)
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")
		navigationController?.navigationBar.addSubview(btnRandom)

		// Repeat button
		let loop = NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRepeat)
		let imageRepeat = UIImage(named:"btn-repeat")
		btnRepeat = UIButton(type:.Custom)
		btnRepeat.frame = CGRect((navigationController?.navigationBar.frame.width)! - 88.0, 0.0, 44.0, 44.0)
		btnRepeat.setImage(imageRepeat?.imageTintedWithColor(UIColor.fromRGB(0xCC0000))?.imageWithRenderingMode(.AlwaysOriginal), forState:.Normal)
		btnRepeat.setImage(imageRepeat?.imageTintedWithColor(UIColor.whiteColor())?.imageWithRenderingMode(.AlwaysOriginal), forState:.Selected)
		btnRepeat.selected = loop
		btnRepeat.addTarget(self, action:#selector(toggleRepeatAction(_:)), forControlEvents:.TouchUpInside)
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")
		navigationController?.navigationBar.addSubview(btnRepeat)

		// Create collection view
		collectionView.registerClass(RootCollectionViewCell.classForCoder(), forCellWithReuseIdentifier:"io.whine.mpdremote.cell.album")
		(collectionView.collectionViewLayout as! UICollectionViewFlowLayout).sectionInset = __insets;
		let w = ceil((/*collectionView.width*/UIScreen.mainScreen().bounds.width / CGFloat(__columns)) - (2 * __sideSpan))
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

	override func viewWillAppear(animated: Bool)
	{
		// Initialize the mpd connection
		if MPDDataSource.shared.server == nil
		{
			if let serverAsData = NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefMPDServer)
			{
				if let server = NSKeyedUnarchiver.unarchiveObjectWithData(serverAsData) as! MPDServer?
				{
					// Data source
					MPDDataSource.shared.server = server
					MPDDataSource.shared.initialize()
					if _displayType != .Albums
					{
						// Always fetch the albums list
						MPDDataSource.shared.getListForDisplayType(.Albums) {}
					}
					MPDDataSource.shared.getListForDisplayType(_displayType) {
						dispatch_async(dispatch_get_main_queue()) {
							self.collectionView.reloadData()
							self._updateNavigationTitle()
						}
					}

					// Player
					MPDPlayer.shared.server = server
					MPDPlayer.shared.initialize()
				}
				else
				{
					let alertController = UIAlertController(title:NYXLocalizedString("lbl_alert_servercfg_error"), message:NYXLocalizedString("lbl_alert_server_need_check"), preferredStyle:.Alert)
					let cancelAction = UIAlertAction(title:NYXLocalizedString("lbl_ok"), style:.Cancel, handler:nil)
					alertController.addAction(cancelAction)
					presentViewController(alertController, animated:true, completion:nil)
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
		if searching
		{
			_hideNavigationBar(animated:true)
		}

		// Deselect cell
		if let idxs = collectionView.indexPathsForSelectedItems()
		{
			for indexPath in idxs
			{
				collectionView.deselectItemAtIndexPath(indexPath, animated:true)
			}
		}
	}

	override func viewWillDisappear(animated: Bool)
	{
		super.viewWillDisappear(animated)

		APP_DELEGATE().operationQueue.cancelAllOperations()
		_downloadOperations.removeAll()
	}

	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
	{
		return .Portrait
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle
	{
		return .LightContent
	}

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
	{
		if segue.identifier == "root-albums-to-detail-album"
		{
			let vc = segue.destinationViewController as! AlbumDetailVC
			vc.albums = searching ? searchResults as! [Album] : MPDDataSource.shared.albums
			vc.selectedIndex = collectionView.indexPathsForSelectedItems()![0].row
		}
		else if segue.identifier == "root-genres-to-artists"
		{
			let row = collectionView.indexPathsForSelectedItems()![0].row
			let genre = searching ? searchResults[row] as! Genre : MPDDataSource.shared.genres[row]
			let vc = segue.destinationViewController as! ArtistsVC
			vc.genre = genre
		}
		else if segue.identifier == "root-artists-to-albums"
		{
			let row = collectionView.indexPathsForSelectedItems()![0].row
			let artist = searching ? searchResults[row] as! Artist : MPDDataSource.shared.artists[row]
			let vc = segue.destinationViewController as! AlbumsVC
			vc.artist = artist
		}
	}

	// MARK: - Gestures
	func doubleTap(gest: UITapGestureRecognizer)
	{
		if gest.state != .Ended
		{
			return
		}

		if let indexPath = collectionView.indexPathForItemAtPoint(gest.locationInView(collectionView))
		{
			switch _displayType
			{
				case .Albums:
					let album = searching ? searchResults[indexPath.row] as! Album : MPDDataSource.shared.albums[indexPath.row]
					MPDPlayer.shared.playAlbum(album, random:NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRandom), loop:NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRepeat))
				case .Artists:
					let artist = searching ? searchResults[indexPath.row] as! Artist : MPDDataSource.shared.artists[indexPath.row]
					MPDDataSource.shared.getAlbumsForArtist(artist) {
						MPDDataSource.shared.getSongsForAlbums(artist.albums) {
							let ar = artist.albums.flatMap({$0.songs}).flatMap({$0})
							MPDPlayer.shared.playTracks(ar, random:NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRandom), loop:NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRepeat))
						}
					}
				case .Genres:
					let genre = searching ? searchResults[indexPath.row] as! Genre : MPDDataSource.shared.genres[indexPath.row]
					MPDDataSource.shared.getAlbumsForGenre(genre) {
						MPDDataSource.shared.getSongsForAlbums(genre.albums) {
							let ar = genre.albums.flatMap({$0.songs}).flatMap({$0})
							MPDPlayer.shared.playTracks(ar, random:NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRandom), loop:NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRepeat))
						}
					}
			}
		}
	}

	func longPress(gest: UILongPressGestureRecognizer)
	{
		if longPressRecognized
		{
			return
		}
		longPressRecognized = true

		if let indexPath = collectionView.indexPathForItemAtPoint(gest.locationInView(collectionView))
		{
			MiniPlayerView.shared.stayHidden = true
			MiniPlayerView.shared.hide()
			let cell = collectionView.cellForItemAtIndexPath(indexPath) as! RootCollectionViewCell
			cell.longPressed = true

			let alertController = UIAlertController(title:nil, message:nil, preferredStyle:.ActionSheet)
			let cancelAction = UIAlertAction(title:NYXLocalizedString("lbl_cancel"), style:.Cancel) { (action) in
				self.longPressRecognized = false
				cell.longPressed = false
				MiniPlayerView.shared.stayHidden = false
			}
			alertController.addAction(cancelAction)

			switch _displayType
			{
				case .Albums:
					let album = searching ? searchResults[indexPath.row] as! Album : MPDDataSource.shared.albums[indexPath.row]
					let playAction = UIAlertAction(title:NYXLocalizedString("lbl_play"), style:.Default) { (action) in
						MPDPlayer.shared.playAlbum(album, random:false, loop:false)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_shuffle"), style:.Default) { (action) in
						MPDPlayer.shared.playAlbum(album, random:true, loop:false)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_addqueue"), style:.Default) { (action) in
						MPDPlayer.shared.addAlbumToQueue(album)
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(addQueueAction)
				case .Artists:
					let artist = searching ? searchResults[indexPath.row] as! Artist : MPDDataSource.shared.artists[indexPath.row]
					let playAction = UIAlertAction(title:NYXLocalizedString("lbl_play"), style:.Default) { (action) in
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
					let shuffleAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_shuffle"), style:.Default) { (action) in
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
					let addQueueAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_addqueue"), style:.Default) { (action) in
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
				case .Genres:
					let genre = self.searching ? self.searchResults[indexPath.row] as! Genre : MPDDataSource.shared.genres[indexPath.row]
					let playAction = UIAlertAction(title:NYXLocalizedString("lbl_play"), style:.Default) { (action) in
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
					let shuffleAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_shuffle"), style:.Default) { (action) in
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
					let addQueueAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_addqueue"), style:.Default) { (action) in
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

			presentViewController(alertController, animated:true, completion:nil)
		}
	}

	// MARK: - Buttons actions
	func changeTypeAction(sender: UIButton?)
	{
		if _typeChoiceView == nil
		{
			_typeChoiceView = TypeChoiceView(frame:CGRect(0.0, 0.0, collectionView.width, 132.0))
			_typeChoiceView.delegate = self
		}

		if _typeChoiceView.superview != nil
		{
			view.backgroundColor = UIColor.fromRGB(0xECECEC)
			UIView.animateWithDuration(0.35, delay:0.0, options:.CurveEaseOut, animations:{
				self.topConstraint.constant = 0.0;
				self.collectionView.layoutIfNeeded()
			}, completion:{ finished in
				self._typeChoiceView.removeFromSuperview()
			})
		}
		else
		{
			view.backgroundColor = UIColor.blackColor()
			_typeChoiceView.tableView.reloadData()
			view.insertSubview(_typeChoiceView, belowSubview:collectionView)
			topConstraint.constant = _typeChoiceView.height;

			UIView.animateWithDuration(0.35, delay:0.0, options:.CurveEaseOut, animations:{
				self.topConstraint.constant = 132.0;
				self.collectionView.layoutIfNeeded()
			}, completion:nil)
		}
	}

	func toggleRandomAction(sender: AnyObject?)
	{
		let prefs = NSUserDefaults.standardUserDefaults()
		let random = !prefs.boolForKey(kNYXPrefRandom)

		btnRandom.selected = random
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		prefs.setBool(random, forKey:kNYXPrefRandom)
		prefs.synchronize()

		MPDPlayer.shared.setRandom(random)
	}

	func toggleRepeatAction(sender: AnyObject?)
	{
		let prefs = NSUserDefaults.standardUserDefaults()
		let loop = !prefs.boolForKey(kNYXPrefRepeat)

		btnRepeat.selected = loop
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

		prefs.setBool(loop, forKey:kNYXPrefRepeat)
		prefs.synchronize()

		MPDPlayer.shared.setRepeat(loop)
	}

	// MARK: - Private
	private func _showNavigationBar(animated animated: Bool = true)
	{
		searchBar.endEditing(true)
		let bar = (navigationController?.navigationBar)!
		UIView.animateWithDuration(animated ? 0.35 : 0.0, delay:0.0, options:.CurveEaseOut, animations:{
			bar.y = 20.0
		}, completion:{ finished in
			self.searchBarVisible = false
		})
	}

	private func _hideNavigationBar(animated animated: Bool = true)
	{
		let bar = (navigationController?.navigationBar)!
		UIView.animateWithDuration(animated ? 0.35 : 0.0, delay:0.0, options:.CurveEaseOut, animations:{
			bar.y = -48.0
		}, completion:{ finished in
			self.searchBarVisible = true
		})
	}

	private func _updateNavigationTitle()
	{
		let p = NSMutableParagraphStyle()
		p.alignment = .Center
		p.lineBreakMode = .ByWordWrapping
		var title = ""
		switch _displayType
		{
			case .Albums:
				let n = MPDDataSource.shared.albums.count
				title = "\(n) \(n > 1 ? NYXLocalizedString("lbl_albums") : NYXLocalizedString("lbl_album"))"
			case .Genres:
				let n = MPDDataSource.shared.genres.count
				title = "\(n) \(n > 1 ? NYXLocalizedString("lbl_genres") : NYXLocalizedString("lbl_genre"))"
			case .Artists:
				let n = MPDDataSource.shared.artists.count
				title = "\(n) \(n > 1 ? NYXLocalizedString("lbl_artists") : NYXLocalizedString("lbl_artist"))"
		}
		let astr1 = NSAttributedString(string:title, attributes:[NSForegroundColorAttributeName : UIColor.whiteColor(), NSFontAttributeName : UIFont(name:"HelveticaNeue-Medium", size:14.0)!, NSParagraphStyleAttributeName : p])
		titleView.setAttributedTitle(astr1, forState:.Normal)
		let astr2 = NSAttributedString(string:title, attributes:[NSForegroundColorAttributeName : UIColor.fromRGB(0xCC0000), NSFontAttributeName : UIFont(name:"HelveticaNeue-Medium", size:14.0)!, NSParagraphStyleAttributeName : p])
		titleView.setAttributedTitle(astr2, forState:.Highlighted)
	}
}

// MARK: - UICollectionViewDataSource
extension RootVC : UICollectionViewDataSource
{
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		if searching
		{
			return searchResults.count
		}
		switch _displayType
		{
			case .Albums:
				return MPDDataSource.shared.albums.count
			case .Genres:
				return MPDDataSource.shared.genres.count
			case .Artists:
				return MPDDataSource.shared.artists.count
		}
	}

	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
	{
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("io.whine.mpdremote.cell.album", forIndexPath:indexPath) as! RootCollectionViewCell
		cell.layer.shouldRasterize = true
		cell.layer.rasterizationScale = UIScreen.mainScreen().scale

		// Sanity check
		if searching && indexPath.row >= searchResults.count
		{
			return cell
		}

		switch _displayType
		{
			case .Albums:
				let album = searching ? searchResults[indexPath.row] as! Album : MPDDataSource.shared.albums[indexPath.row]
				_configureCellForAlbum(cell, indexPath:indexPath, album:album)
			case .Genres:
				let genre = searching ? searchResults[indexPath.row] as! Genre : MPDDataSource.shared.genres[indexPath.row]
				_configureCellForGenre(cell, indexPath:indexPath, genre:genre)
			case .Artists:
				let artist = searching ? searchResults[indexPath.row] as! Artist : MPDDataSource.shared.artists[indexPath.row]
				_configureCellForArtist(cell, indexPath:indexPath, artist:artist)
		}

		return cell
	}

	private func _configureCellForAlbum(cell: RootCollectionViewCell, indexPath: NSIndexPath, album: Album)
	{
		// Set title
		cell.label.text = album.name
		cell.accessibilityLabel = album.name

		// If image is in cache, bail out quickly
		if let cachedImage = ImageCache.shared[album.name]
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
			ImageCache.shared[album.name] = cover
		}
		else
		{
			if album.path != nil
			{
				_downloadCoverForAlbum(album, cropSize:cell.imageView.size) { (cover: UIImage, thumbnail: UIImage) in
					dispatch_async(dispatch_get_main_queue()) {
						if let c = self.collectionView.cellForItemAtIndexPath(indexPath) as? RootCollectionViewCell
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
						dispatch_async(dispatch_get_main_queue()) {
							if let c = self.collectionView.cellForItemAtIndexPath(indexPath) as? RootCollectionViewCell
							{
								c.image = thumbnail
							}
						}
					}
				}
			}
		}
	}

	private func _configureCellForGenre(cell: RootCollectionViewCell, indexPath: NSIndexPath, genre: Genre)
	{
		cell.label.text = genre.name
		cell.accessibilityLabel = genre.name

		if NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefWEBServer) == nil
		{
			cell.image = generateCoverForGenre(genre, size: cell.imageView.size)
			return
		}

		if let album = genre.albums.first
		{
			// If image is in cache, bail out quickly
			if let cachedImage = ImageCache.shared[album.name]
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
				ImageCache.shared[album.name] = cover
			}
			else
			{
				cell.image = generateCoverForGenre(genre, size: cell.imageView.size)
				if album.path != nil
				{
					_downloadCoverForAlbum(album, cropSize:cell.imageView.size) { (cover: UIImage, thumbnail: UIImage) in
						dispatch_async(dispatch_get_main_queue()) {
							if let c = self.collectionView.cellForItemAtIndexPath(indexPath) as? RootCollectionViewCell
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
							dispatch_async(dispatch_get_main_queue()) {
								if let c = self.collectionView.cellForItemAtIndexPath(indexPath) as? RootCollectionViewCell
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
				dispatch_async(dispatch_get_main_queue()) {
					if let _ = self.collectionView.cellForItemAtIndexPath(indexPath) as? RootCollectionViewCell
					{
						self.collectionView.reloadItemsAtIndexPaths([indexPath])
					}
				}
			}
			return
		}
	}

	private func _configureCellForArtist(cell: RootCollectionViewCell, indexPath: NSIndexPath, artist: Artist)
	{
		cell.label.text = artist.name
		cell.accessibilityLabel = artist.name

		if NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefWEBServer) == nil
		{
			cell.image = generateCoverForArtist(artist, size: cell.imageView.size)
			return
		}

		if artist.albums.count > 0
		{
			if let album = artist.albums.first
			{
				// If image is in cache, bail out quickly
				if let cachedImage = ImageCache.shared[album.name]
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
					ImageCache.shared[album.name] = cover
				}
				else
				{
					let sizeAsData = NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefCoverSize)!
					let cropSize = NSKeyedUnarchiver.unarchiveObjectWithData(sizeAsData) as! NSValue
					if album.path != nil
					{
						_downloadCoverForAlbum(album, cropSize:cropSize.CGSizeValue()) { (cover: UIImage, thumbnail: UIImage) in
							let cropped = thumbnail.imageCroppedToFitSize(cell.imageView.size)
							dispatch_async(dispatch_get_main_queue()) {
								if let c = self.collectionView.cellForItemAtIndexPath(indexPath) as? RootCollectionViewCell
								{
									c.image = cropped
								}
							}
						}
					}
					else
					{
						MPDDataSource.shared.getPathForAlbum(album) {
							self._downloadCoverForAlbum(album, cropSize:cropSize.CGSizeValue()) { (cover: UIImage, thumbnail: UIImage) in
								let cropped = thumbnail.imageCroppedToFitSize(cell.imageView.size)
								dispatch_async(dispatch_get_main_queue()) {
									if let c = self.collectionView.cellForItemAtIndexPath(indexPath) as? RootCollectionViewCell
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
				dispatch_async(dispatch_get_main_queue()) {
					if let _ = self.collectionView.cellForItemAtIndexPath(indexPath) as? RootCollectionViewCell
					{
						self.collectionView.reloadItemsAtIndexPaths([indexPath])
					}
				}
			}
		}
	}

	private func _downloadCoverForAlbum(album: Album, cropSize: CGSize, callback:(cover: UIImage, thumbnail: UIImage) -> Void)
	{
		let downloadOperation = CoverOperation(album:album, cropSize:cropSize)
		let key = album.name + album.year
		weak var weakOperation = downloadOperation
		downloadOperation.cplBlock = {(cover: UIImage, thumbnail: UIImage) in
			if let op = weakOperation
			{
				if !op.cancelled
				{
					self._downloadOperations.removeValueForKey(key)
				}
			}
			callback(cover:cover, thumbnail:thumbnail)
		}
		_downloadOperations[key] = downloadOperation
		APP_DELEGATE().operationQueue.addOperation(downloadOperation)
	}
}

// MARK: - UICollectionViewDelegate
extension RootVC : UICollectionViewDelegate
{
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
	{
		// If menu is visible ignore default behavior and hide it
		if menuView.visible
		{
			collectionView.deselectItemAtIndexPath(indexPath, animated:false)
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
			case .Albums:
				performSegueWithIdentifier("root-albums-to-detail-album", sender: self)
			case .Genres:
				performSegueWithIdentifier("root-genres-to-artists", sender: self)
			case .Artists:
				performSegueWithIdentifier("root-artists-to-albums", sender: self)
		}
	}

	func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath)
	{
		if _displayType != .Albums
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
			_downloadOperations.removeValueForKey(key)
			Logger.dlog("[+] Cancelling \(op)")
		}
	}
}

// MARK: - UIScrollViewDelegate
extension RootVC : UIScrollViewDelegate
{
	func scrollViewDidScroll(scrollView: UIScrollView)
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

	func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool)
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
	func searchBarCancelButtonClicked(searchBar: UISearchBar)
	{
		searchResults.removeAll()
		searching = false
		searchBar.text = ""
		searchBar.resignFirstResponder()
		_showNavigationBar(animated:true)
		//searchBarVisible = false
		collectionView.reloadData()
	}

	func searchBarSearchButtonClicked(searchBar: UISearchBar)
	{
		collectionView.reloadData()
		searchBar.endEditing(true)
	}

	func searchBarTextDidBeginEditing(searchBar: UISearchBar)
	{
		searching = true
	}

	func searchBarTextDidEndEditing(searchBar: UISearchBar)
	{
		//searching = false
		//searchResults.removeAll()
	}

	func searchBar(searchBar: UISearchBar, textDidChange searchText: String)
	{
		switch _displayType
		{
			case .Albums:
				if MPDDataSource.shared.albums.count > 0
				{
					searchResults = MPDDataSource.shared.albums.filter({$0.name.lowercaseString.containsString(searchText.lowercaseString)})
				}
			case .Genres:
				if MPDDataSource.shared.genres.count > 0
				{
					searchResults = MPDDataSource.shared.genres.filter({$0.name.lowercaseString.containsString(searchText.lowercaseString)})
				}
			case .Artists:
				if MPDDataSource.shared.artists.count > 0
				{
					searchResults = MPDDataSource.shared.artists.filter({$0.name.lowercaseString.containsString(searchText.lowercaseString)})
				}
		}
		collectionView.reloadData()
	}
}

// MARK: - TypeChoiceViewDelegate
extension RootVC : TypeChoiceViewDelegate
{
	func didSelectType(type: DisplayType)
	{
		// Ignore if type did not change
		changeTypeAction(nil)
		if _displayType == type
		{
			return
		}
		_displayType = type

		NSUserDefaults.standardUserDefaults().setInteger(type.rawValue, forKey:kNYXPrefDisplayType)
		NSUserDefaults.standardUserDefaults().synchronize()

		// Refresh view
		MPDDataSource.shared.getListForDisplayType(type) {
			dispatch_async(dispatch_get_main_queue()) {
				self.collectionView.setContentOffset(CGPointZero, animated:true)
				self.collectionView.reloadData()
				self._updateNavigationTitle()
			}
		}
	}
}

// MARK: - UIResponder
extension RootVC
{
	override func canBecomeFirstResponder() -> Bool
	{
		return true
	}

	override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?)
	{
		if motion == .MotionShake
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
			let sizeAsData = NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefCoverSize)!
			let cropSize = NSKeyedUnarchiver.unarchiveObjectWithData(sizeAsData) as! NSValue
			MPDDataSource.shared.getPathForAlbum(randomAlbum) {
				self._downloadCoverForAlbum(randomAlbum, cropSize:cropSize.CGSizeValue(), callback:{ (cover: UIImage, thumbnail: UIImage) in
					let size = CGSize(self.view.width - 64.0, self.view.width - 64.0)
					let cropped = cover.imageCroppedToFitSize(size)
					dispatch_async(dispatch_get_main_queue()) {
						let iv = UIImageView(frame:CGRect((self.view.width - 64.0) * 0.5, (self.view.height - 64.0) * 0.5, 64.0, 64.0))
						iv.image = cropped
						iv.alpha = 0.0
						self.view.addSubview(iv)
						UIView.animateWithDuration(1.0, delay:0.0, options:.CurveEaseIn, animations:{
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
