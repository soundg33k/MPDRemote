// AlbumsVC.swift
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


final class AlbumsVC : UITableViewController
{
	// MARK: - Private properties
	// Selected artist
	var artist: Artist!
	// Label in the navigationbar
	private var titleView: UILabel! = nil
	// Keep track of download operations to eventually cancel them
	private var _downloadOperations = [String : NSOperation]()

	// MARK: - Initializers
	required init?(coder aDecoder: NSCoder)
	{
		self.artist = nil
		super.init(coder:aDecoder)
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Remove back button label
		navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)

		// Tableview
		tableView.tableFooterView = UIView()

		// Navigation bar title
		titleView = UILabel(frame:CGRect(CGPointZero, 100.0, 44.0))
		titleView.numberOfLines = 2
		titleView.textAlignment = .Center
		titleView.isAccessibilityElement = false
		titleView.textColor = navigationController?.navigationBar.tintColor
		titleView.backgroundColor = navigationController?.navigationBar.barTintColor
		navigationItem.titleView = titleView
	}

	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)

		if artist.albums.count <= 0
		{
			MPDDataSource.shared.getAlbumsForArtist(artist) {
				dispatch_async(dispatch_get_main_queue()) {
					self.tableView.reloadData()
					self._updateNavigationTitle()
				}
			}
		}

		_updateNavigationTitle()
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
		if segue.identifier == "albums-to-albumdetail"
		{
			let vc = segue.destinationViewController as! AlbumDetailVC
			vc.selectedIndex = tableView.indexPathForSelectedRow!.row
			vc.albums = artist.albums
		}
	}

	// MARK: - Private
	private func _updateNavigationTitle()
	{
		let attrs = NSMutableAttributedString(string:artist.name + "\n", attributes:[NSFontAttributeName : UIFont(name:"HelveticaNeue-Medium", size:14.0)!])
		attrs.appendAttributedString(NSAttributedString(string:"\(artist.albums.count) \(artist.albums.count > 1 ? NYXLocalizedString("lbl_albums").lowercaseString : NYXLocalizedString("lbl_album").lowercaseString)", attributes:[NSFontAttributeName : UIFont(name:"HelveticaNeue", size:13.0)!]))
		titleView.attributedText = attrs
	}
}

// MARK: - UITableViewDataSource
extension AlbumsVC
{
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return artist.albums.count + 1 // dummy
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCellWithIdentifier("io.whine.mpdremote.cell.album", forIndexPath:indexPath) as! AlbumTableViewCell

		// Dummy to let some space for the mini player
		if indexPath.row == artist.albums.count
		{
			cell.coverView.image = nil
			cell.lblAlbum.text = ""
			cell.separator.hidden = true
			cell.accessoryType = .None
			cell.selectionStyle = .None
			return cell
		}

		let album = artist.albums[indexPath.row]
		cell.lblAlbum.text = album.name
		cell.separator.hidden = false
		cell.accessoryType = .DisclosureIndicator
		cell.accessibilityLabel = "\(album.name)"

		// No server for covers
		if NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefWEBServer) == nil
		{
			cell.coverView.image = generateCoverForAlbum(album, size: cell.coverView.size)
			return cell
		}

		// Get local URL for cover
		guard let coverURL = album.localCoverURL else
		{
			Logger.alog("[!] No cover URL for \(album)") // should not happen
			cell.coverView.image = generateCoverForAlbum(album, size: cell.coverView.size)
			return cell
		}

		if let cover = UIImage.loadFromURL(coverURL)
		{
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
				let cropped = cover.imageCroppedToFitSize(cell.coverView.size)
				dispatch_async(dispatch_get_main_queue()) {
					if let c = self.tableView.cellForRowAtIndexPath(indexPath) as? AlbumTableViewCell
					{
						c.coverView.image = cropped
					}
				}
			}
		}
		else
		{
			cell.coverView.image = generateCoverForAlbum(album, size: cell.coverView.size)
			let sizeAsData = NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefCoverSize)!
			let cropSize = NSKeyedUnarchiver.unarchiveObjectWithData(sizeAsData) as! NSValue
			if album.path != nil
			{
				_downloadCoverForAlbum(album, cropSize:cropSize.CGSizeValue()) { (thumbnail: UIImage) in
					let cropped = thumbnail.imageCroppedToFitSize(cell.coverView.size)
					dispatch_async(dispatch_get_main_queue()) {
						if let c = self.tableView.cellForRowAtIndexPath(indexPath) as? AlbumTableViewCell
						{
							c.coverView.image = cropped
						}
					}
				}
			}
			else
			{
				MPDDataSource.shared.getPathForAlbum(album) {
					self._downloadCoverForAlbum(album, cropSize:cropSize.CGSizeValue()) { (thumbnail: UIImage) in
						let cropped = thumbnail.imageCroppedToFitSize(cell.coverView.size)
						dispatch_async(dispatch_get_main_queue()) {
							if let c = self.tableView.cellForRowAtIndexPath(indexPath) as? AlbumTableViewCell
							{
								c.coverView.image = cropped
							}
						}
					}
				}
			}
		}

		return cell
	}

	private func _downloadCoverForAlbum(album: Album, cropSize: CGSize, callback:(thumbnail: UIImage) -> Void)
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
			callback(thumbnail:thumbnail)
		}
		_downloadOperations[key] = downloadOperation
		APP_DELEGATE().operationQueue.addOperation(downloadOperation)
	}
}

// MARK: - UITableViewDelegate
extension AlbumsVC
{
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		// Dummy, ignore
		if indexPath.row == artist.albums.count
		{
			return
		}

		performSegueWithIdentifier("albums-to-albumdetail", sender: self)
	}
	
	override func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
	{
		// Dummy, ignore
		if indexPath.row == artist.albums.count
		{
			return
		}

		// Remove download cover operation if still in queue
		let album = artist.albums[indexPath.row]
		let key = album.name + album.year
		if let op = _downloadOperations[key] as! CoverOperation?
		{
			op.cancel()
			_downloadOperations.removeValueForKey(key)
			Logger.dlog("[+] Cancelling \(op)")
		}
	}

	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
	{
		if indexPath.row == artist.albums.count
		{
			return 44.0 // dummy cell
		}
		return 74.0
	}
}