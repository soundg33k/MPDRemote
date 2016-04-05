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
	// MARK: - Public properties
	// Albums view
	private(set) var collectionView: UICollectionView!
	// Button in the navigationbar
	private(set) var titleView: UIButton! = nil
	// Detailed album view
	private(set) var detailVC: AlbumDetailVC! = nil
	// Should show the search view, flag
	private(set) var searchBarVisible = false
	// Is currently searching, flag
	private(set) var searching = false
	// Search results
	private(set) var searchResults = [Album]()
	// Long press gesture is recognized, flag
	private(set) var longPressRecognized = false

	// MARK: - Private properties
	// Keep track of download operations to eventually cancel them
	private let _downloadOperations = NSMutableDictionary()

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()
		self.automaticallyAdjustsScrollViewInsets = false
		self.view.backgroundColor = UIColor.fromRGB(0xECECEC)

		// Customize navbar
		let headerColor = UIColor.whiteColor()
		let navigationBar = (self.navigationController?.navigationBar)!
		navigationBar.barTintColor = UIColor.fromRGB(kNYXAppColor)
		navigationBar.tintColor = headerColor
		navigationBar.translucent = false
		navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : headerColor]
		navigationBar.setBackgroundImage(UIImage(), forBarPosition:.Any, barMetrics:.Default)
		navigationBar.shadowImage = UIImage()
		self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)

		// Searchbar
		let searchView = UIView(frame:CGRect(0.0, 0.0, navigationBar.width, 64.0))
		searchView.backgroundColor = navigationBar.barTintColor
		self.navigationController?.view.insertSubview(searchView, belowSubview:navigationBar)
		let sb = UISearchBar(frame:navigationBar.frame)
		sb.searchBarStyle = .Minimal
		sb.barTintColor = searchView.backgroundColor
		sb.tintColor = navigationBar.tintColor
		(sb.valueForKey("searchField") as? UITextField)?.textColor = headerColor
		sb.showsCancelButton = true
		sb.delegate = self
		searchView.addSubview(sb)

		// Navigation bar title
		self.titleView = UIButton(frame:CGRect(0.0, 0.0, 100.0, navigationBar.height))
		let p = NSMutableParagraphStyle()
		p.alignment = .Center
		p.lineBreakMode = .ByWordWrapping
		let astr1 = NSAttributedString(string:"Albums", attributes:[NSForegroundColorAttributeName : UIColor.whiteColor(), NSFontAttributeName : UIFont.systemFontOfSize(14.0), NSParagraphStyleAttributeName : p])
		self.titleView.setAttributedTitle(astr1, forState:.Normal)
		let astr2 = NSAttributedString(string:"Albums", attributes:[NSForegroundColorAttributeName : UIColor.fromRGB(0xCC0000), NSFontAttributeName : UIFont.systemFontOfSize(14.0), NSParagraphStyleAttributeName : p])
		self.titleView.setAttributedTitle(astr2, forState:.Highlighted)
		self.titleView.addTarget(self, action:#selector(RootVC.changeTypeAction(_:)), forControlEvents:.TouchUpInside)
		self.navigationItem.titleView = self.titleView

		// Create collection view
		let layout = UICollectionViewFlowLayout()
		self.collectionView = UICollectionView(frame:CGRect(0.0, 0.0, self.view.width, self.view.height - 64.0), collectionViewLayout:layout)
		self.collectionView.dataSource = self
		self.collectionView.delegate = self
		self.collectionView.registerClass(AlbumCollectionViewCell.classForCoder(), forCellWithReuseIdentifier:"io.whine.mpdremote.cell.album")
		self.collectionView.backgroundColor = self.view.backgroundColor
		self.collectionView.scrollsToTop = true
		self.view.addSubview(self.collectionView)

		// Longpress
		let longPress = UILongPressGestureRecognizer(target:self, action:#selector(RootVC.longPress(_:)))
		longPress.minimumPressDuration = 0.5
		longPress.delaysTouchesBegan = true
		self.collectionView.addGestureRecognizer(longPress)

		// Double tap
		let doubleTap = UITapGestureRecognizer(target:self, action:#selector(RootVC.doubleTap(_:)))
		doubleTap.numberOfTapsRequired = 2
		doubleTap.numberOfTouchesRequired = 1
		doubleTap.delaysTouchesBegan = true
		self.collectionView.addGestureRecognizer(doubleTap)

		// Register to some notifications
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(RootVC.miniPlayerWillShow(_:)), name:kNYXNotificationMiniPlayerViewWillShow, object:nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(RootVC.miniPlayerWillHide(_:)), name:kNYXNotificationMiniPlayerViewWillHide, object:nil)
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
					MPDDataSource.shared.server = server
					MPDDataSource.shared.initialize()
					MPDDataSource.shared.fill({
						dispatch_async(dispatch_get_main_queue(), {
							self.collectionView.reloadData()
						})
					})

					MPDPlayer.shared.server = server
					MPDPlayer.shared.initialize()
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
		if self.detailVC != nil
		{
			if let idxs = self.collectionView.indexPathsForSelectedItems()
			{
				for indexPath in idxs
				{
					self.collectionView.deselectItemAtIndexPath(indexPath, animated:true)
				}
			}
		}
	}

	override func viewWillDisappear(animated: Bool)
	{
		super.viewWillDisappear(animated)
		APP_DELEGATE().operationQueue.cancelAllOperations()
		self._downloadOperations.removeAllObjects()
	}

	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
	{
		return .Portrait
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle
	{
		return .LightContent
	}

	// MARK: - Public
	func doubleTap(gest: UITapGestureRecognizer)
	{
		if (gest.state == .Ended)
		{
			let point = gest.locationInView(self.collectionView)
			if let indexPath = self.collectionView.indexPathForItemAtPoint(point)
			{
				let album = self.searching ? self.searchResults[indexPath.row] : MPDDataSource.shared.albums[indexPath.row]
				MPDPlayer.shared.playAlbum(album, random:NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRandom), loop:NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRepeat))
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

		let point = gest.locationInView(self.collectionView)

		if let indexPath = self.collectionView.indexPathForItemAtPoint(point)
		{
			MiniPlayerView.shared.stayHidden = true
			MiniPlayerView.shared.hide()
			let cell = self.collectionView.cellForItemAtIndexPath(indexPath) as! AlbumCollectionViewCell
			cell.longPressed = true
			let album = self.searching ? self.searchResults[indexPath.row] : MPDDataSource.shared.albums[indexPath.row]

			let alertController = UIAlertController(title:nil, message:nil, preferredStyle:.ActionSheet)
			let cancelAction = UIAlertAction(title:NYXLocalizedString("lbl_cancel"), style:.Cancel) { (action) in
				self.longPressRecognized = false
				cell.longPressed = false
				MiniPlayerView.shared.stayHidden = false
			}
			alertController.addAction(cancelAction)
			let playAction = UIAlertAction(title:NYXLocalizedString("lbl_alert_playalbum"), style:.Default) { (action) in
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
			self.presentViewController(alertController, animated:true, completion:nil)
		}
	}

	// MARK: - Buttons actions
	func changeTypeAction(sender: UIButton?)
	{
		Logger.dlog("Not implemented yet.")
	}

	// MARK: - Notifications
	func miniPlayerWillShow(aNotification: NSNotification?)
	{
		//self.collectionView.frame = CGRect(self.collectionView.origin, self.collectionView.width, self.collectionView.height - MiniPlayerView.shared.height)
	}

	func miniPlayerWillHide(aNotification: NSNotification?)
	{
		//self.collectionView.frame = CGRect(self.collectionView.origin, self.collectionView.width, self.collectionView.height + MiniPlayerView.shared.height)
	}

	// MARK: - Private
	private func _showNavigationBar(animated animated: Bool)
	{
		let bar = (self.navigationController?.navigationBar)!
		UIView.animateWithDuration(animated ? 0.35 : 0.0, delay:0.0, options:.CurveEaseOut, animations:{
			bar.y = 20.0
		}, completion:nil)
	}

	private func _hideNavigationBar(animated animated: Bool)
	{
		let bar = (self.navigationController?.navigationBar)!
		UIView.animateWithDuration(animated ? 0.35 : 0.0, delay:0.0, options:.CurveEaseOut, animations:{
			bar.y = -48.0
		}, completion:nil)
	}
}

// MARK: - UICollectionViewDataSource
extension RootVC : UICollectionViewDataSource
{
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		return self.searching ? self.searchResults.count : MPDDataSource.shared.albums.count
	}

	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
	{
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("io.whine.mpdremote.cell.album", forIndexPath:indexPath) as! AlbumCollectionViewCell
		cell.layer.shouldRasterize = true
		cell.layer.rasterizationScale = UIScreen.mainScreen().scale

		let album = self.searching ? self.searchResults[indexPath.row] : MPDDataSource.shared.albums[indexPath.row]
		cell.label.text = album.name
		cell.accessibilityLabel = album.name

		// No cover, abort
		if !album.hasCover
		{
			cell.image = UIImage(named:"default-cover")
			return cell
		}

		guard let coverURL = album.localCoverURL else
		{
			cell.image = UIImage(named:"default-cover")
			return cell
		}
		if let cover = UIImage.loadFromURL(coverURL)
		{
			cell.image = cover
		}
		else
		{
			cell.image = UIImage(named:"default-cover")
			let sizeAsData = NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefCoverSize)!
			let cropSize = NSKeyedUnarchiver.unarchiveObjectWithData(sizeAsData) as! NSValue
			if album.path != nil
			{
				let op = DownloadCoverOperation(album:album, cropSize:cropSize.CGSizeValue())
				let key = album.name + album.year
				weak var wo = op
				op.cplBlock = {(thumbnail: UIImage, cover: UIImage) in
					dispatch_async(dispatch_get_main_queue(), {
						if let c = self.collectionView.cellForItemAtIndexPath(indexPath) as? AlbumCollectionViewCell
						{
							c.image = thumbnail
						}
					})
					if let x = wo
					{
						if !x.cancelled
						{
							self._downloadOperations.removeObjectForKey(key)
						}
					}
				}
				self._downloadOperations[key] = op
				APP_DELEGATE().operationQueue.addOperation(op)
			}
			else
			{
				MPDDataSource.shared.findCoverPathForAlbum(album, callback: {
					let op = DownloadCoverOperation(album:album, cropSize:cropSize.CGSizeValue())
					let key = album.name + album.year
					weak var wo = op
					op.cplBlock = {(thumbnail: UIImage, cover: UIImage) in
						dispatch_async(dispatch_get_main_queue(), {
							if let c = self.collectionView.cellForItemAtIndexPath(indexPath) as? AlbumCollectionViewCell
							{
								c.image = thumbnail
							}
						})
						if let x = wo
						{
							if !x.cancelled
							{
								self._downloadOperations.removeObjectForKey(key)
							}
						}
					}
					self._downloadOperations[key] = op
					APP_DELEGATE().operationQueue.addOperation(op)
				})
			}
		}
		
		return cell
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

		// Create detail VC
		if self.detailVC == nil
		{
			self.detailVC = AlbumDetailVC()
		}

		// Set data according to search state
		self.detailVC.selectedIndex = indexPath.row
		self.detailVC.albums = self.searching ? self.searchResults : MPDDataSource.shared.albums

		// Hide the searchbar
		if self.searchBarVisible
		{
			self._showNavigationBar(animated:true)
		}
		self.navigationController?.pushViewController(self.detailVC, animated:true)
	}

	func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath)
	{
		// When searching things can go wrong, this prevent some crashes
		let src = self.searching ? self.searchResults : MPDDataSource.shared.albums
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
			self._downloadOperations.removeObjectForKey(key)
			Logger.dlog("[+] Cancelling \(op)")
		}
	}
}

// MARK: - UICollectionViewDelegateFlowLayout
extension RootVC : UICollectionViewDelegateFlowLayout
{
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
	{
		let w = ceil((collectionView.width / CGFloat(__columns)) - (2 * __sideSpan))
		return CGSize(w, w + 20.0)
	}

	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets
	{
		return __insets
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
		self.searchBarVisible = false
		self.searching = false
		self.searchResults.removeAll()
		self._showNavigationBar(animated:true)
		self.collectionView.reloadData()
	}

	func searchBarTextDidBeginEditing(searchBar: UISearchBar)
	{
		self.searching = true
	}

	func searchBarTextDidEndEditing(searchBar: UISearchBar)
	{
		self.searching = false
		self.searchResults.removeAll()
	}

	func searchBar(searchBar: UISearchBar, textDidChange searchText: String)
	{
		if MPDDataSource.shared.albums.count > 0
		{
			self.searchResults = MPDDataSource.shared.albums.filter({$0.name.lowercaseString.containsString(searchText.lowercaseString)})
			self.collectionView.reloadData()
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
				MPDDataSource.shared.getSongsForAlbum(randomAlbum, callback:{
					MPDPlayer.shared.playAlbum(randomAlbum, random:false, loop:false)
				})
			}
			else
			{
				MPDPlayer.shared.playAlbum(randomAlbum, random:false, loop:false)
			}
		}
	}
}
