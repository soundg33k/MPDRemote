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
		self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)

		// Customize navbar
		let headerColor = UIColor.whiteColor()
		let navigationBar = (self.navigationController?.navigationBar)!

		// Searchbar
		let searchView = UIView(frame:CGRect(0.0, 0.0, navigationBar.width, 64.0))
		searchView.backgroundColor = navigationBar.barTintColor
		self.navigationController?.view.insertSubview(searchView, belowSubview:navigationBar)
		self.searchBar = UISearchBar(frame:navigationBar.frame)
		self.searchBar.searchBarStyle = .Minimal
		self.searchBar.barTintColor = searchView.backgroundColor
		self.searchBar.tintColor = navigationBar.tintColor
		(self.searchBar.valueForKey("searchField") as? UITextField)?.textColor = headerColor
		self.searchBar.showsCancelButton = true
		self.searchBar.delegate = self
		searchView.addSubview(self.searchBar)

		// Navigation bar title
		self.titleView = UIButton(frame:CGRect(0.0, 0.0, 100.0, navigationBar.height))
		self.titleView.addTarget(self, action:#selector(changeTypeAction(_:)), forControlEvents:.TouchUpInside)
		self.navigationItem.titleView = self.titleView

		// Random button
		let random = NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRandom)
		let imageRandom = UIImage(named:"btn-random")
		self.btnRandom = UIButton(type:.Custom)
		self.btnRandom.frame = CGRect((self.navigationController?.navigationBar.frame.width)! - 44.0, 0.0, 44.0, 44.0)
		self.btnRandom.setImage(imageRandom?.imageTintedWithColor(UIColor.fromRGB(0xCC0000))?.imageWithRenderingMode(.AlwaysOriginal), forState:.Normal)
		self.btnRandom.setImage(imageRandom?.imageTintedWithColor(UIColor.whiteColor())?.imageWithRenderingMode(.AlwaysOriginal), forState:.Selected)
		self.btnRandom.selected = random
		self.btnRandom.addTarget(self, action:#selector(toggleRandomAction(_:)), forControlEvents:.TouchUpInside)
		self.btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")
		self.navigationController?.navigationBar.addSubview(self.btnRandom)

		// Repeat button
		let loop = NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRepeat)
		let imageRepeat = UIImage(named:"btn-repeat")
		self.btnRepeat = UIButton(type:.Custom)
		self.btnRepeat.frame = CGRect((self.navigationController?.navigationBar.frame.width)! - 88.0, 0.0, 44.0, 44.0)
		self.btnRepeat.setImage(imageRepeat?.imageTintedWithColor(UIColor.fromRGB(0xCC0000))?.imageWithRenderingMode(.AlwaysOriginal), forState:.Normal)
		self.btnRepeat.setImage(imageRepeat?.imageTintedWithColor(UIColor.whiteColor())?.imageWithRenderingMode(.AlwaysOriginal), forState:.Selected)
		self.btnRepeat.selected = loop
		self.btnRepeat.addTarget(self, action:#selector(toggleRepeatAction(_:)), forControlEvents:.TouchUpInside)
		self.btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")
		self.navigationController?.navigationBar.addSubview(self.btnRepeat)

		// Create collection view
		self.collectionView.registerClass(AlbumCollectionViewCell.classForCoder(), forCellWithReuseIdentifier:"io.whine.mpdremote.cell.album")
		(self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout).sectionInset = __insets;
		let w = ceil((/*collectionView.width*/UIScreen.mainScreen().bounds.width / CGFloat(__columns)) - (2 * __sideSpan))
		(self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize = CGSize(w, w + 20.0);

		// Longpress
		let longPress = UILongPressGestureRecognizer(target:self, action:#selector(longPress(_:)))
		longPress.minimumPressDuration = 0.5
		longPress.delaysTouchesBegan = true
		self.collectionView.addGestureRecognizer(longPress)

		// Double tap
		let doubleTap = UITapGestureRecognizer(target:self, action:#selector(doubleTap(_:)))
		doubleTap.numberOfTapsRequired = 2
		doubleTap.numberOfTouchesRequired = 1
		doubleTap.delaysTouchesBegan = true
		self.collectionView.addGestureRecognizer(doubleTap)

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
					if self._displayType != .Albums
					{
						// Always fetch the albums list
						MPDDataSource.shared.getListForDisplayType(.Albums, callback:{})
					}
					MPDDataSource.shared.getListForDisplayType(self._displayType, callback:{
						dispatch_async(dispatch_get_main_queue()) {
							self.collectionView.reloadData()
							self._updateNavigationTitle()
						}
					})

					// Player
					MPDPlayer.shared.server = server
					MPDPlayer.shared.initialize()
				}
				else
				{
					let alertController = UIAlertController(title:NYXLocalizedString("lbl_alert_servercfg_error"), message:NYXLocalizedString("lbl_alert_server_need_check"), preferredStyle:.Alert)
					let cancelAction = UIAlertAction(title:NYXLocalizedString("lbl_ok"), style:.Cancel, handler:nil)
					alertController.addAction(cancelAction)
					self.presentViewController(alertController, animated:true, completion:nil)
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
		if self.searching
		{
			self._hideNavigationBar(animated:true)
		}

		// Deselect cell
		if let idxs = self.collectionView.indexPathsForSelectedItems()
		{
			for indexPath in idxs
			{
				self.collectionView.deselectItemAtIndexPath(indexPath, animated:true)
			}
		}
	}

	override func viewWillDisappear(animated: Bool)
	{
		super.viewWillDisappear(animated)

		APP_DELEGATE().operationQueue.cancelAllOperations()
		self._downloadOperations.removeAll()
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
			vc.albums = self.searching ? self.searchResults as! [Album] : MPDDataSource.shared.albums
			vc.selectedIndex = self.collectionView.indexPathsForSelectedItems()![0].row
		}
		else if segue.identifier == "root-genres-to-artists"
		{
			let row = self.collectionView.indexPathsForSelectedItems()![0].row
			let genre = self.searching ? self.searchResults[row] as! Genre : MPDDataSource.shared.genres[row]
			let vc = segue.destinationViewController as! ArtistsVC
			vc.genre = genre
		}
		else if segue.identifier == "root-artists-to-albums"
		{
			let row = self.collectionView.indexPathsForSelectedItems()![0].row
			let artist = self.searching ? self.searchResults[row] as! Artist : MPDDataSource.shared.artists[row]
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

		if let indexPath = self.collectionView.indexPathForItemAtPoint(gest.locationInView(self.collectionView))
		{
			switch self._displayType
			{
				case .Albums:
					let album = self.searching ? self.searchResults[indexPath.row] as! Album : MPDDataSource.shared.albums[indexPath.row]
					MPDPlayer.shared.playAlbum(album, random:NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRandom), loop:NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRepeat))
				case .Artists:
					let artist = self.searching ? self.searchResults[indexPath.row] as! Artist : MPDDataSource.shared.artists[indexPath.row]
					MPDDataSource.shared.getAlbumsForArtist(artist, callback:{
						MPDDataSource.shared.getSongsForAlbums(artist.albums, callback: {
							let ar = artist.albums.flatMap({$0.songs}).flatMap({$0})
							MPDPlayer.shared.playTracks(ar, random:NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRandom), loop:NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRepeat))
						})
					})
				case .Genres:
					let genre = self.searching ? self.searchResults[indexPath.row] as! Genre : MPDDataSource.shared.genres[indexPath.row]
					MPDDataSource.shared.getAlbumsForGenre(genre, callback:{
						MPDDataSource.shared.getSongsForAlbums(genre.albums, callback: {
							let ar = genre.albums.flatMap({$0.songs}).flatMap({$0})
							MPDPlayer.shared.playTracks(ar, random:NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRandom), loop:NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRepeat))
						})
					})
			}
		}
	}

	func longPress(gest: UILongPressGestureRecognizer)
	{
		if self.longPressRecognized
		{
			return
		}
		self.longPressRecognized = true

		if let indexPath = self.collectionView.indexPathForItemAtPoint(gest.locationInView(self.collectionView))
		{
			MiniPlayerView.shared.stayHidden = true
			MiniPlayerView.shared.hide()
			let cell = self.collectionView.cellForItemAtIndexPath(indexPath) as! AlbumCollectionViewCell
			cell.longPressed = true

			let alertController = UIAlertController(title:nil, message:nil, preferredStyle:.ActionSheet)
			let cancelAction = UIAlertAction(title:NYXLocalizedString("lbl_cancel"), style:.Cancel) { (action) in
				self.longPressRecognized = false
				cell.longPressed = false
				MiniPlayerView.shared.stayHidden = false
			}
			alertController.addAction(cancelAction)

			switch self._displayType
			{
				case .Albums:
					let album = self.searching ? self.searchResults[indexPath.row] as! Album : MPDDataSource.shared.albums[indexPath.row]
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
					let artist = self.searching ? self.searchResults[indexPath.row] as! Artist : MPDDataSource.shared.artists[indexPath.row]
					let playAction = UIAlertAction(title:NYXLocalizedString("lbl_play"), style:.Default) { (action) in
						MPDDataSource.shared.getAlbumsForArtist(artist, callback:{
							MPDDataSource.shared.getSongsForAlbums(artist.albums, callback: {
								let ar = artist.albums.flatMap({$0.songs}).flatMap({$0})
								MPDPlayer.shared.playTracks(ar, random:false, loop:false)
							})
						})
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_shuffle"), style:.Default) { (action) in
						MPDDataSource.shared.getAlbumsForArtist(artist, callback:{
							MPDDataSource.shared.getSongsForAlbums(artist.albums, callback: {
								let ar = artist.albums.flatMap({$0.songs}).flatMap({$0})
								MPDPlayer.shared.playTracks(ar, random:true, loop:false)
							})
						})
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_addqueue"), style:.Default) { (action) in
						MPDDataSource.shared.getAlbumsForArtist(artist, callback:{
							for album in artist.albums
							{
								MPDPlayer.shared.addAlbumToQueue(album)
							}
						})
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(addQueueAction)
				case .Genres:
					let genre = self.searching ? self.searchResults[indexPath.row] as! Genre : MPDDataSource.shared.genres[indexPath.row]
					let playAction = UIAlertAction(title:NYXLocalizedString("lbl_play"), style:.Default) { (action) in
						MPDDataSource.shared.getAlbumsForGenre(genre, callback:{
							MPDDataSource.shared.getSongsForAlbums(genre.albums, callback: {
								let ar = genre.albums.flatMap({$0.songs}).flatMap({$0})
								MPDPlayer.shared.playTracks(ar, random:false, loop:false)
							})
						})
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(playAction)
					let shuffleAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_shuffle"), style:.Default) { (action) in
						MPDDataSource.shared.getAlbumsForGenre(genre, callback:{
							MPDDataSource.shared.getSongsForAlbums(genre.albums, callback: {
								let ar = genre.albums.flatMap({$0.songs}).flatMap({$0})
								MPDPlayer.shared.playTracks(ar, random:true, loop:false)
							})
						})
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(shuffleAction)
					let addQueueAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum_addqueue"), style:.Default) { (action) in
						MPDDataSource.shared.getAlbumsForGenre(genre, callback:{
							for album in genre.albums
							{
								MPDPlayer.shared.addAlbumToQueue(album)
							}
						})
						self.longPressRecognized = false
						cell.longPressed = false
						MiniPlayerView.shared.stayHidden = false
					}
					alertController.addAction(addQueueAction)
			}

			self.presentViewController(alertController, animated:true, completion:nil)
		}
	}

	// MARK: - Buttons actions
	func changeTypeAction(sender: UIButton?)
	{
		if self._typeChoiceView == nil
		{
			self._typeChoiceView = TypeChoiceView(frame:CGRect(0.0, 0.0, self.collectionView.width, 132.0))
			self._typeChoiceView.delegate = self
		}

		if self._typeChoiceView.superview != nil
		{
			self.view.backgroundColor = UIColor.fromRGB(0xECECEC)
			UIView.animateWithDuration(0.35, delay:0.0, options:.CurveEaseOut, animations:{
				self.topConstraint.constant = 0.0;
				self.collectionView.layoutIfNeeded()
			}, completion:{ finished in
				self._typeChoiceView.removeFromSuperview()
			})
		}
		else
		{
			self.view.backgroundColor = UIColor.blackColor()
			self._typeChoiceView.tableView.reloadData()
			self.view.insertSubview(self._typeChoiceView, belowSubview:self.collectionView)
			self.topConstraint.constant = self._typeChoiceView.height;

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

		self.btnRandom.selected = random
		self.btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

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

	// MARK: - Private
	private func _showNavigationBar(animated animated: Bool = true)
	{
		self.searchBar.endEditing(true)
		let bar = (self.navigationController?.navigationBar)!
		UIView.animateWithDuration(animated ? 0.35 : 0.0, delay:0.0, options:.CurveEaseOut, animations:{
			bar.y = 20.0
		}, completion:{ finished in
			self.searchBarVisible = false
		})
	}

	private func _hideNavigationBar(animated animated: Bool = true)
	{
		let bar = (self.navigationController?.navigationBar)!
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
		switch self._displayType
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
		self.titleView.setAttributedTitle(astr1, forState:.Normal)
		let astr2 = NSAttributedString(string:title, attributes:[NSForegroundColorAttributeName : UIColor.fromRGB(0xCC0000), NSFontAttributeName : UIFont(name:"HelveticaNeue-Medium", size:14.0)!, NSParagraphStyleAttributeName : p])
		self.titleView.setAttributedTitle(astr2, forState:.Highlighted)
	}
}

// MARK: - UICollectionViewDataSource
extension RootVC : UICollectionViewDataSource
{
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		if self.searching
		{
			return self.searchResults.count
		}
		switch self._displayType
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
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("io.whine.mpdremote.cell.album", forIndexPath:indexPath) as! AlbumCollectionViewCell
		cell.layer.shouldRasterize = true
		cell.layer.rasterizationScale = UIScreen.mainScreen().scale

		// Sanity check
		if self.searching && indexPath.row >= self.searchResults.count
		{
			return cell
		}

		switch self._displayType
		{
			case .Albums:
				let album = self.searching ? self.searchResults[indexPath.row] as! Album : MPDDataSource.shared.albums[indexPath.row]
				self._configureCellForAlbum(cell, indexPath:indexPath, album:album)
			case .Genres:
				let genre = self.searching ? self.searchResults[indexPath.row] as! Genre : MPDDataSource.shared.genres[indexPath.row]
				self._configureCellForGenre(cell, indexPath:indexPath, genre:genre)
			case .Artists:
				let artist = self.searching ? self.searchResults[indexPath.row] as! Artist : MPDDataSource.shared.artists[indexPath.row]
				self._configureCellForArtist(cell, indexPath:indexPath, artist:artist)
		}

		return cell
	}

	private func _configureCellForAlbum(cell: AlbumCollectionViewCell, indexPath: NSIndexPath, album: Album)
	{
		// Set title
		cell.label.text = album.name
		cell.accessibilityLabel = album.name

		if NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefWEBServer) == nil
		{
			//self._configureCellWithString(cell, indexPath:indexPath, string:album.name)
			cell.image = generateCoverForAlbum(album, size: cell.imageView.size)
			return
		}

		// No cover, abort
		if !album.hasCover
		{
			//cell.image = UIImage(named:"default-cover")
			cell.image = generateCoverForAlbum(album, size: cell.imageView.size)
			return
		}

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
			//cell.image = UIImage(named:"default-cover")
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
			cell.image = generateCoverForAlbum(album, size: cell.imageView.size)
			if album.path != nil
			{
				self._downloadCoverForAlbum(album, cropSize:cell.imageView.size, callback:{ (cover: UIImage, thumbnail: UIImage) in
					dispatch_async(dispatch_get_main_queue()) {
						if let c = self.collectionView.cellForItemAtIndexPath(indexPath) as? AlbumCollectionViewCell
						{
							c.image = thumbnail
						}
					}
				})
			}
			else
			{
				MPDDataSource.shared.getPathForAlbum(album, callback: {
					self._downloadCoverForAlbum(album, cropSize:cell.imageView.size, callback:{ (cover: UIImage, thumbnail: UIImage) in
						dispatch_async(dispatch_get_main_queue()) {
							if let c = self.collectionView.cellForItemAtIndexPath(indexPath) as? AlbumCollectionViewCell
							{
								c.image = thumbnail
							}
						}
					})
				})
			}
		}
	}

	private func _configureCellForGenre(cell: AlbumCollectionViewCell, indexPath: NSIndexPath, genre: Genre)
	{
		cell.label.text = genre.name
		cell.accessibilityLabel = genre.name

		if NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefWEBServer) == nil
		{
			//self._configureCellWithString(cell, indexPath:indexPath, string:genre.name)
			cell.image = generateCoverForGenre(genre, size: cell.imageView.size)
			return
		}

		if let album = genre.albums.first
		{
			// No cover, abort
			if !album.hasCover
			{
				//cell.image = UIImage(named:"default-cover")
				cell.image = generateCoverForGenre(genre, size: cell.imageView.size)
				return
			}

			// Get local URL for cover
			guard let coverURL = album.localCoverURL else
			{
				Logger.alog("[!] No cover URL for \(album)") // should not happen
				//cell.image = UIImage(named:"default-cover")
				cell.image = generateCoverForGenre(genre, size: cell.imageView.size)
				return
			}

			// If image is in cache, bail out quickly
			if let cachedImage = ImageCache.shared[album.name]
			{
				cell.image = cachedImage
				return
			}

			if let cover = UIImage.loadFromURL(coverURL)
			{
				cell.image = cover
				ImageCache.shared[album.name] = cover
			}
			else
			{
				//cell.image = UIImage(named:"default-cover")
				cell.image = generateCoverForGenre(genre, size: cell.imageView.size)
				if album.path != nil
				{
					self._downloadCoverForAlbum(album, cropSize:cell.imageView.size, callback:{ (cover: UIImage, thumbnail: UIImage) in
						dispatch_async(dispatch_get_main_queue()) {
							if let c = self.collectionView.cellForItemAtIndexPath(indexPath) as? AlbumCollectionViewCell
							{
								c.image = thumbnail
							}
						}
					})
				}
				else
				{
					MPDDataSource.shared.getPathForAlbum(album, callback: {
						self._downloadCoverForAlbum(album, cropSize:cell.imageView.size, callback:{ (cover: UIImage, thumbnail: UIImage) in
							dispatch_async(dispatch_get_main_queue()) {
								if let c = self.collectionView.cellForItemAtIndexPath(indexPath) as? AlbumCollectionViewCell
								{
									c.image = thumbnail
								}
							}
						})
					})
				}
			}
		}
		else
		{
			//cell.image = UIImage(named:"default-cover")
			cell.image = generateCoverForGenre(genre, size: cell.imageView.size)
			MPDDataSource.shared.getAlbumForGenre(genre, callback: {
				dispatch_async(dispatch_get_main_queue()) {
					if let _ = self.collectionView.cellForItemAtIndexPath(indexPath) as? AlbumCollectionViewCell
					{
						self.collectionView.reloadItemsAtIndexPaths([indexPath])
					}
				}
			})
			return
		}
	}

	private func _configureCellForArtist(cell: AlbumCollectionViewCell, indexPath: NSIndexPath, artist: Artist)
	{
		cell.label.text = artist.name
		cell.accessibilityLabel = artist.name

		if NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefWEBServer) == nil
		{
			//self._configureCellWithString(cell, indexPath:indexPath, string:artist.name)
			cell.image = generateCoverForArtist(artist, size: cell.imageView.size)
			return
		}

		if artist.albums.count > 0
		{
			if let album = artist.albums.first
			{
				// No cover, abort
				if !album.hasCover
				{
					//cell.image = UIImage(named:"default-cover")
					cell.image = generateCoverForArtist(artist, size: cell.imageView.size)
					return
				}

				// Get local URL for cover
				guard let coverURL = album.localCoverURL else
				{
					Logger.alog("[!] No cover URL for \(album)") // should not happen
					//cell.image = UIImage(named:"default-cover")
					cell.image = generateCoverForArtist(artist, size: cell.imageView.size)
					return
				}

				// If image is in cache, bail out quickly
				if let cachedImage = ImageCache.shared[album.name]
				{
					cell.image = cachedImage
					return
				}

				if let cover = UIImage.loadFromURL(coverURL)
				{
					cell.image = cover
					ImageCache.shared[album.name] = cover
				}
				else
				{
					//cell.image = UIImage(named:"default-cover")
					cell.image = generateCoverForArtist(artist, size: cell.imageView.size)
					let sizeAsData = NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefCoverSize)!
					let cropSize = NSKeyedUnarchiver.unarchiveObjectWithData(sizeAsData) as! NSValue
					if album.path != nil
					{
						self._downloadCoverForAlbum(album, cropSize:cropSize.CGSizeValue(), callback:{ (cover: UIImage, thumbnail: UIImage) in
							let cropped = thumbnail.imageCroppedToFitSize(cell.imageView.size)
							dispatch_async(dispatch_get_main_queue()) {
								if let c = self.collectionView.cellForItemAtIndexPath(indexPath) as? AlbumCollectionViewCell
								{
									c.image = cropped
								}
							}
						})
					}
					else
					{
						MPDDataSource.shared.getPathForAlbum(album, callback: {
							self._downloadCoverForAlbum(album, cropSize:cropSize.CGSizeValue(), callback:{ (cover: UIImage, thumbnail: UIImage) in
								let cropped = thumbnail.imageCroppedToFitSize(cell.imageView.size)
								dispatch_async(dispatch_get_main_queue()) {
									if let c = self.collectionView.cellForItemAtIndexPath(indexPath) as? AlbumCollectionViewCell
									{
										c.image = cropped
									}
								}
							})
						})
					}
				}
			}
		}
		else
		{
			MPDDataSource.shared.getAlbumsForArtist(artist, callback:{
				dispatch_async(dispatch_get_main_queue()) {
					if let _ = self.collectionView.cellForItemAtIndexPath(indexPath) as? AlbumCollectionViewCell
					{
						self.collectionView.reloadItemsAtIndexPaths([indexPath])
					}
				}
			})
		}
	}

	private func _downloadCoverForAlbum(album: Album, cropSize: CGSize, callback:(cover: UIImage, thumbnail: UIImage) -> Void)
	{
		let downloadOperation = DownloadCoverOperation(album:album, cropSize:cropSize)
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
		self._downloadOperations[key] = downloadOperation
		APP_DELEGATE().operationQueue.addOperation(downloadOperation)
	}
}

// MARK: - UICollectionViewDelegate
extension RootVC : UICollectionViewDelegate
{
	func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
	{
		// If menu is visible ignore default behavior and hide it
		if self.menuView.visible
		{
			collectionView.deselectItemAtIndexPath(indexPath, animated:false)
			self.showLeftViewAction(nil)
			return
		}

		// Hide the searchbar
		if self.searchBarVisible
		{
			self._showNavigationBar(animated:true)
		}

		switch self._displayType
		{
			case .Albums:
				self.performSegueWithIdentifier("root-albums-to-detail-album", sender: self)
			case .Genres:
				self.performSegueWithIdentifier("root-genres-to-artists", sender: self)
			case .Artists:
				self.performSegueWithIdentifier("root-artists-to-albums", sender: self)
		}
	}

	func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath)
	{
		if self._displayType != .Albums
		{
			return
		}

		// When searching things can go wrong, this prevent some crashes
		let src = self.searching ? self.searchResults as! [Album] : MPDDataSource.shared.albums
		if indexPath.row >= src.count
		{
			return
		}

		// Remove download cover operation if still in queue
		let album = src[indexPath.row]
		let key = album.name + album.year
		if let op = self._downloadOperations[key] as! DownloadCoverOperation?
		{
			op.cancel()
			self._downloadOperations.removeValueForKey(key)
			Logger.dlog("[+] Cancelling \(op)")
		}
	}
}

// MARK: - UIScrollViewDelegate
extension RootVC : UIScrollViewDelegate
{
	func scrollViewDidScroll(scrollView: UIScrollView)
	{
		if self.searchBarVisible
		{
			if scrollView.contentOffset.y > 0.0
			{
				self._showNavigationBar(animated:true)
			}
			return
		}
		let bar = (self.navigationController?.navigationBar)!
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
			self.searchBarVisible = true
			let bar = (self.navigationController?.navigationBar)!
			bar.y = -48.0
			self.searchBar.becomeFirstResponder()
		}
		else
		{
			self.searchBarVisible = false
		}
	}
}

// MARK: - UISearchBarDelegate
extension RootVC : UISearchBarDelegate
{
	func searchBarCancelButtonClicked(searchBar: UISearchBar)
	{
		self.searchResults.removeAll()
		self.searching = false
		searchBar.text = ""
		searchBar.resignFirstResponder()
		self._showNavigationBar(animated:true)
		//self.searchBarVisible = false
		self.collectionView.reloadData()
	}

	func searchBarSearchButtonClicked(searchBar: UISearchBar)
	{
		self.collectionView.reloadData()
		self.searchBar.endEditing(true)
	}

	func searchBarTextDidBeginEditing(searchBar: UISearchBar)
	{
		self.searching = true
	}

	func searchBarTextDidEndEditing(searchBar: UISearchBar)
	{
		//self.searching = false
		//self.searchResults.removeAll()
	}

	func searchBar(searchBar: UISearchBar, textDidChange searchText: String)
	{
		switch self._displayType
		{
			case .Albums:
				if MPDDataSource.shared.albums.count > 0
				{
					self.searchResults = MPDDataSource.shared.albums.filter({$0.name.lowercaseString.containsString(searchText.lowercaseString)})
				}
			case .Genres:
				if MPDDataSource.shared.genres.count > 0
				{
					self.searchResults = MPDDataSource.shared.genres.filter({$0.name.lowercaseString.containsString(searchText.lowercaseString)})
				}
			case .Artists:
				if MPDDataSource.shared.artists.count > 0
				{
					self.searchResults = MPDDataSource.shared.artists.filter({$0.name.lowercaseString.containsString(searchText.lowercaseString)})
				}
		}
		self.collectionView.reloadData()
	}
}

// MARK: - TypeChoiceViewDelegate
extension RootVC : TypeChoiceViewDelegate
{
	func didSelectType(type: DisplayType)
	{
		// Ignore if type did not change
		self.changeTypeAction(nil)
		if self._displayType == type
		{
			return
		}
		self._displayType = type

		NSUserDefaults.standardUserDefaults().setInteger(type.rawValue, forKey:kNYXPrefDisplayType)
		NSUserDefaults.standardUserDefaults().synchronize()

		// Refresh view
		MPDDataSource.shared.getListForDisplayType(type, callback:{
			dispatch_async(dispatch_get_main_queue()) {
				self.collectionView.setContentOffset(CGPointZero, animated:true)
				self.collectionView.reloadData()
				self._updateNavigationTitle()
			}
		})
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
				MPDDataSource.shared.getSongsForAlbum(randomAlbum, callback:{
					MPDPlayer.shared.playAlbum(randomAlbum, random:false, loop:false)
				})
			}
			else
			{
				MPDPlayer.shared.playAlbum(randomAlbum, random:false, loop:false)
			}

			// Briefly display cover of album
			let sizeAsData = NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefCoverSize)!
			let cropSize = NSKeyedUnarchiver.unarchiveObjectWithData(sizeAsData) as! NSValue
			MPDDataSource.shared.getPathForAlbum(randomAlbum, callback: {
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
			})
		}
	}
}
