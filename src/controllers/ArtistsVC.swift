// ArtistsVC.swift
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


final class ArtistsVC : UITableViewController
{
	// MARK: - Private properties
	// Selected genre
	var genre: Genre! = nil
	// List of artists
	private var artists = [Artist]()
	// Label in the navigationbar
	private var titleView: UILabel! = nil
	// Keep track of download operations to eventually cancel them
	private var _downloadOperations = [String : Operation]()

	// MARK: - Initializers
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder:aDecoder)
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Remove back button label
		navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)

		// Tableview
		tableView.tableFooterView = UIView()

		// Navigation bar title
		titleView = UILabel(frame:CGRect(CGPoint.zero, 100.0, 44.0))
		titleView.numberOfLines = 2
		titleView.textAlignment = .center
		titleView.isAccessibilityElement = false
		titleView.textColor = navigationController?.navigationBar.tintColor
		titleView.backgroundColor = navigationController?.navigationBar.barTintColor
		navigationItem.titleView = titleView
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		MPDDataSource.shared.getArtistsForGenre(genre) { (artists: [Artist]) in
			self.artists = artists
			DispatchQueue.main.async {
				self.tableView.reloadData()
				self._updateNavigationTitle()
			}
		}
	}

	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
	{
		return .portrait
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle
	{
		return .lightContent
	}

	override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?)
	{
		if segue.identifier == "artists-to-albums"
		{
			let vc = segue.destinationViewController as! AlbumsVC
			vc.artist = artists[tableView.indexPathForSelectedRow!.row]
		}
	}

	// MARK: - Private
	private func _updateNavigationTitle()
	{
		let attrs = NSMutableAttributedString(string:genre.name + "\n", attributes:[NSFontAttributeName : UIFont(name:"HelveticaNeue-Medium", size:14.0)!])
		attrs.append(AttributedString(string:"\(artists.count) \(artists.count > 1 ? NYXLocalizedString("lbl_artists").lowercased() : NYXLocalizedString("lbl_artist").lowercased())", attributes:[NSFontAttributeName : UIFont(name:"HelveticaNeue", size:13.0)!]))
		titleView.attributedText = attrs
	}
}

// MARK: - UITableViewDataSource
extension ArtistsVC
{
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return artists.count + 1 // dummy
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "io.whine.mpdremote.cell.artist", for:indexPath) as! ArtistTableViewCell

		// Dummy to let some space for the mini player
		if indexPath.row == artists.count
		{
			cell.lblArtist.text = ""
			cell.lblAlbums.text = ""
			cell.separator.isHidden = true
			cell.coverView.image = nil
			cell.accessoryType = .none
			cell.selectionStyle = .none
			return cell
		}

		let artist = artists[indexPath.row]
		cell.lblArtist.text = artist.name
		cell.separator.isHidden = false
		cell.accessoryType = .disclosureIndicator
		cell.accessibilityLabel = "\(artist.name), \(artist.albums.count) \(artist.albums.count > 1 ? NYXLocalizedString("lbl_albums").lowercased() : NYXLocalizedString("lbl_album").lowercased())"

		// No server for covers
		if UserDefaults.standard().data(forKey: kNYXPrefWEBServer) == nil
		{
			cell.coverView.image = generateCoverForArtist(artist, size: cell.coverView.size)
			return cell
		}

		if artist.albums.count > 0
		{
			cell.lblAlbums.text = "\(artist.albums.count) \(artist.albums.count > 1 ? NYXLocalizedString("lbl_albums").lowercased() : NYXLocalizedString("lbl_album").lowercased())"
			if let album = artist.albums.first
			{
				// Get local URL for cover
				guard let coverURL = album.localCoverURL else
				{
					Logger.alog("[!] No cover URL for \(album)") // should not happen
					cell.coverView.image = generateCoverForArtist(artist, size: cell.coverView.size)
					return cell
				}

				if let cover = UIImage.loadFromURL(coverURL)
				{
					DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes.qosUserInitiated).async {
						let cropped = cover.imageCroppedToFitSize(cell.coverView.size)
						DispatchQueue.main.async {
							if let c = self.tableView.cellForRow(at: indexPath) as? ArtistTableViewCell
							{
								c.coverView.image = cropped
							}
						}
					}
				}
				else
				{
					cell.coverView.image = generateCoverForArtist(artist, size: cell.coverView.size)
					let sizeAsData = UserDefaults.standard().data(forKey: kNYXPrefCoverSize)!
					let cropSize = NSKeyedUnarchiver.unarchiveObject(with: sizeAsData) as! NSValue
					if album.path != nil
					{
						_downloadCoverForAlbum(album, cropSize:cropSize.cgSizeValue()) { (thumbnail: UIImage) in
							let cropped = thumbnail.imageCroppedToFitSize(cell.coverView.size)
							DispatchQueue.main.async {
								if let c = self.tableView.cellForRow(at: indexPath) as? ArtistTableViewCell
								{
									c.coverView.image = cropped
								}
							}
						}
					}
					else
					{
						MPDDataSource.shared.getPathForAlbum(album) {
							self._downloadCoverForAlbum(album, cropSize:cropSize.cgSizeValue()) { (thumbnail: UIImage) in
								let cropped = thumbnail.imageCroppedToFitSize(cell.coverView.size)
								DispatchQueue.main.async {
									if let c = self.tableView.cellForRow(at: indexPath) as? ArtistTableViewCell
									{
										c.coverView.image = cropped
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
					if let _ = self.tableView.cellForRow(at: indexPath) as? ArtistTableViewCell
					{
						self.tableView.reloadRows(at: [indexPath], with:.none)
					}
				}
			}
		}
		return cell
	}

	private func _downloadCoverForAlbum(_ album: Album, cropSize: CGSize, callback:(thumbnail: UIImage) -> Void)
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
			callback(thumbnail:thumbnail)
		}
		_downloadOperations[key] = downloadOperation
		APP_DELEGATE().operationQueue.addOperation(downloadOperation)
	}
}

// MARK: - UITableViewDelegate
extension ArtistsVC
{
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		if indexPath.row == artists.count
		{
			return
		}

		performSegue(withIdentifier: "artists-to-albums", sender: self)
	}

	override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath)
	{
		if indexPath.row == artists.count
		{
			return
		}

		// Remove download cover operation if still in queue
		let artist = artists[indexPath.row]
		guard let album = artist.albums.first else {return}
		let key = album.name + album.year
		if let op = _downloadOperations[key] as! CoverOperation?
		{
			op.cancel()
			_downloadOperations.removeValue(forKey: key)
			Logger.dlog("[+] Cancelling \(op)")
		}
	}

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		if indexPath.row == artists.count
		{
			return 44.0
		}
		return 58.0
	}
}
