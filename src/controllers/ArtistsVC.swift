// ArtistsVC.swift
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


final class ArtistsVC : UITableViewController
{
	// MARK: - Public properties
	// Selected genre
	var genre: Genre! = nil
	// List of artists
	var artists = [Artist]()

	// MARK: - Private properties
	// Label in the navigationbar
	private var titleView: UILabel! = nil
	// Keep track of download operations to eventually cancel them
	fileprivate var _downloadOperations = [String : Operation]()

	// MARK: - Initializers
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Remove back button label
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

		// Navigation bar title
		titleView = UILabel(frame: CGRect(.zero, 100.0, 44.0))
		titleView.numberOfLines = 2
		titleView.textAlignment = .center
		titleView.isAccessibilityElement = false
		titleView.textColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
		navigationItem.titleView = titleView

		// Tableview
		tableView.tableFooterView = UIView()
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		MusicDataSource.shared.getArtistsForGenre(genre) { (artists: [Artist]) in
			self.artists = artists
			DispatchQueue.main.async {
				self.tableView.reloadData()
				self.updateNavigationTitle()
			}
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
		if segue.identifier == "artists-to-albums"
		{
			let vc = segue.destination as! AlbumsVC
			vc.artist = artists[tableView.indexPathForSelectedRow!.row]
		}
	}

	// MARK: - Private
	private func updateNavigationTitle()
	{
		let attrs = NSMutableAttributedString(string: genre.name + "\n", attributes: [NSFontAttributeName : UIFont(name: "HelveticaNeue-Medium", size: 14.0)!])
		attrs.append(NSAttributedString(string: "\(artists.count) \(artists.count == 1 ? NYXLocalizedString("lbl_artist").lowercased() : NYXLocalizedString("lbl_artists").lowercased())", attributes: [NSFontAttributeName : UIFont(name: "HelveticaNeue", size: 13.0)!]))
		titleView.attributedText = attrs
	}

	fileprivate func downloadCoverForAlbum(_ album: Album, cropSize: CGSize, callback:@escaping (_ thumbnail: UIImage) -> Void)
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
			callback(thumbnail)
		}
		_downloadOperations[key] = downloadOperation
		APP_DELEGATE().operationQueue.addOperation(downloadOperation)
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
		let cell = tableView.dequeueReusableCell(withIdentifier: "io.whine.mpdremote.cell.artist", for: indexPath) as! ArtistTableViewCell

		// Dummy to let some space for the mini player
		if indexPath.row == artists.count
		{
			cell.isHidden = true
			cell.selectionStyle = .none
			cell.lblAlbums.tag = 789
			return cell
		}

		let artist = artists[indexPath.row]
		cell.lblArtist.text = artist.name
		cell.accessibilityLabel = "\(artist.name), \(artist.albums.count) \(artist.albums.count == 1 ? NYXLocalizedString("lbl_album").lowercased() : NYXLocalizedString("lbl_albums").lowercased())"

		// No server for covers
		cell.coverView.image = nil
		if UserDefaults.standard.data(forKey: kNYXPrefWEBServer) == nil
		{
			return cell
		}

		if artist.albums.count > 0
		{
			cell.lblAlbums.text = "\(artist.albums.count) \(artist.albums.count == 1 ? NYXLocalizedString("lbl_album").lowercased() : NYXLocalizedString("lbl_albums").lowercased())"
			if let album = artist.albums.first
			{
				// Get local URL for cover
				guard let coverURL = album.localCoverURL else
				{
					Logger.alog("[!] No cover URL for \(album)") // should not happen
					cell.coverView.image = generateCoverForArtist(artist, size: cell.coverView.size)
					return cell
				}

				if let cover = UIImage.loadFromFileURL(coverURL)
				{
					DispatchQueue.global(qos: .userInitiated).async {
						let cropped = cover.smartCropped(toSize: cell.coverView.size)
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
					let sizeAsData = UserDefaults.standard.data(forKey: kNYXPrefCoversSize)!
					let cropSize = NSKeyedUnarchiver.unarchiveObject(with: sizeAsData) as! NSValue
					if album.path != nil
					{
						downloadCoverForAlbum(album, cropSize: cropSize.cgSizeValue) { (thumbnail: UIImage) in
							let cropped = thumbnail.smartCropped(toSize: cell.coverView.size)
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
						MusicDataSource.shared.getPathForAlbum(album) {
							self.downloadCoverForAlbum(album, cropSize: cropSize.cgSizeValue) { (thumbnail: UIImage) in
								let cropped = thumbnail.smartCropped(toSize: cell.coverView.size)
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
			cell.lblAlbums.text = ""
			MusicDataSource.shared.getAlbumsForArtist(artist) {
				DispatchQueue.main.async {
					if let _ = self.tableView.cellForRow(at: indexPath) as? ArtistTableViewCell
					{
						self.tableView.reloadRows(at: [indexPath], with: .none)
					}
				}
			}
		}
		return cell
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
		let key = album.uniqueIdentifier
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
		return 52.0
	}
}
