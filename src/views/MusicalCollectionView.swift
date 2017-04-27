// MusicalCollectionView.swift
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


protocol MusicalCollectionViewDelegate : class
{
	func isSearching(actively: Bool) -> Bool
	func didSelectItem(indexPath: IndexPath)
}


final class MusicalCollectionView : UICollectionView
{
	// MARK: - Properties
	// Data sources
	var items = [MusicalEntity]()
	var searchResults = [MusicalEntity]()
	// Type of entities displayd
	var displayType = DisplayType.albums
	// Delegate
	weak var myDelegate: MusicalCollectionViewDelegate!
	// Cover download operations
	fileprivate var _downloadOperations = [String : Operation]()

	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)

		self.dataSource = self
		self.delegate = self
		self.isPrefetchingEnabled = false

		// Layout
		let sideSpan = CGFloat(10.0)
		let columns = 3
		let itemWidth = ceil((UIScreen.main.bounds.width / CGFloat(columns)) - (2 * sideSpan))
		let layout = UICollectionViewFlowLayout()
		layout.sectionInset = UIEdgeInsets(top: sideSpan, left: sideSpan, bottom: sideSpan, right: sideSpan)
		layout.itemSize = CGSize(itemWidth, itemWidth + 20.0)
		self.collectionViewLayout = layout
		self.register(MusicalEntityCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: "fr.whine.mpdremote.cell.album")
	}

	// MARK: - Private
	fileprivate func downloadCoverForAlbum(_ album: Album, cropSize: CGSize, callback:((_ cover: UIImage, _ thumbnail: UIImage) -> Void)?)
	{
		let downloadOperation = CoverOperation(album: album, cropSize: cropSize)
		let key = album.uniqueIdentifier
		weak var weakOperation = downloadOperation
		downloadOperation.callback = {(cover: UIImage, thumbnail: UIImage) in
			if let op = weakOperation
			{
				if op.isCancelled == false
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
}

// MARK: - UICollectionViewDataSource
extension MusicalCollectionView : UICollectionViewDataSource
{
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		if myDelegate.isSearching(actively: false)
		{
			return searchResults.count
		}

		return items.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
	{
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fr.whine.mpdremote.cell.album", for: indexPath) as! MusicalEntityCollectionViewCell
		cell.layer.shouldRasterize = true
		cell.layer.rasterizationScale = UIScreen.main.scale
		cell.label.textColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
		cell.label.backgroundColor = collectionView.backgroundColor

		// Sanity check
		let searching = myDelegate.isSearching(actively: false)
		if searching && indexPath.row >= searchResults.count
		{
			return cell
		}

		switch displayType
		{
		case .albums:
			let album = searching ? searchResults[indexPath.row] as! Album : items[indexPath.row] as! Album
			_configureCellForAlbum(cell, indexPath: indexPath, album: album)
		case .genres:
			let genre = searching ? searchResults[indexPath.row] as! Genre : items[indexPath.row] as! Genre
			_configureCellForGenre(cell, indexPath: indexPath, genre: genre)
		case .artists:
			let artist = searching ? searchResults[indexPath.row] as! Artist : items[indexPath.row] as! Artist
			_configureCellForArtist(cell, indexPath: indexPath, artist: artist)
		case .playlists:
			let playlist = searching ? searchResults[indexPath.row] as! Playlist : items[indexPath.row] as! Playlist
			_configureCellForPlaylist(cell, indexPath: indexPath, playlist: playlist)
		}

		return cell
	}

	private func _configureCellForAlbum(_ cell: MusicalEntityCollectionViewCell, indexPath: IndexPath, album: Album)
	{
		// Set title
		cell.label.text = album.name
		cell.accessibilityLabel = album.name

		// If image is in cache, bail out quickly
		cell.image = nil
		if let cachedImage = ImageCache.shared[album.uniqueIdentifier]
		{
			cell.image = cachedImage
			return
		}

		// Get local URL for cover
		guard let _ = UserDefaults.standard.data(forKey: kNYXPrefWEBServer) else
		{
			return
		}
		guard let coverURL = album.localCoverURL else
		{
			Logger.dlog("[!] No cover file URL for \(album)") // should not happen
			return
		}

		if let cover = UIImage.loadFromFileURL(coverURL)
		{
			cell.image = cover
			ImageCache.shared[album.uniqueIdentifier] = cover
		}
		else
		{
			if myDelegate.isSearching(actively: true) //searching && searchBar.isFirstResponder == true
			{
				return
			}
			if album.path != nil
			{
				downloadCoverForAlbum(album, cropSize: cell.imageView.size) { (cover: UIImage, thumbnail: UIImage) in
					DispatchQueue.main.async {
						if let c = self.cellForItem(at: indexPath) as? MusicalEntityCollectionViewCell
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
							if let c = self.cellForItem(at: indexPath) as? MusicalEntityCollectionViewCell
							{
								c.image = thumbnail
							}
						}
					}
				}
			}
		}
	}

	private func _configureCellForGenre(_ cell: MusicalEntityCollectionViewCell, indexPath: IndexPath, genre: Genre)
	{
		cell.label.text = genre.name
		cell.accessibilityLabel = genre.name

		if let album = genre.albums.first
		{
			// If image is in cache, bail out quickly
			cell.image = nil
			if let cachedImage = ImageCache.shared[album.uniqueIdentifier]
			{
				cell.image = cachedImage
				return
			}

			// Get local URL for cover
			guard let _ = UserDefaults.standard.data(forKey: kNYXPrefWEBServer) else
			{
				return
			}
			guard let coverURL = album.localCoverURL else
			{
				Logger.alog("[!] No cover URL for \(album)") // should not happen
				return
			}

			if let cover = UIImage.loadFromFileURL(coverURL)
			{
				cell.image = cover
				ImageCache.shared[album.uniqueIdentifier] = cover
			}
			else
			{
				if myDelegate.isSearching(actively: true) //searching && searchBar.isFirstResponder == true
				{
					return
				}
				if album.path != nil
				{
					downloadCoverForAlbum(album, cropSize: cell.imageView.size) { (cover: UIImage, thumbnail: UIImage) in
						DispatchQueue.main.async {
							if let c = self.cellForItem(at: indexPath) as? MusicalEntityCollectionViewCell
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
								if let c = self.cellForItem(at: indexPath) as? MusicalEntityCollectionViewCell
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
			if myDelegate.isSearching(actively: true) //searching && searchBar.isFirstResponder == true
			{
				return
			}
			MusicDataSource.shared.getAlbumForGenre(genre) {
				DispatchQueue.main.async {
					if let _ = self.cellForItem(at: indexPath) as? MusicalEntityCollectionViewCell
					{
						self.reloadItems(at: [indexPath])
					}
				}
			}
			return
		}
	}

	private func _configureCellForArtist(_ cell: MusicalEntityCollectionViewCell, indexPath: IndexPath, artist: Artist)
	{
		cell.label.text = artist.name
		cell.accessibilityLabel = artist.name

		if artist.albums.count > 0
		{
			if let album = artist.albums.first
			{
				// If image is in cache, bail out quickly
				cell.image = nil
				if let cachedImage = ImageCache.shared[album.uniqueIdentifier]
				{
					cell.image = cachedImage
					return
				}

				// Get local URL for cover
				guard let _ = UserDefaults.standard.data(forKey: kNYXPrefWEBServer) else
				{
					return
				}
				guard let coverURL = album.localCoverURL else
				{
					Logger.alog("[!] No cover URL for \(album)") // should not happen
					return
				}

				if let cover = UIImage.loadFromFileURL(coverURL)
				{
					cell.image = cover
					ImageCache.shared[album.uniqueIdentifier] = cover
				}
				else
				{
					if myDelegate.isSearching(actively: true) //searching && searchBar.isFirstResponder == true
					{
						return
					}
					let sizeAsData = UserDefaults.standard.data(forKey: kNYXPrefCoversSize)!
					let cropSize = NSKeyedUnarchiver.unarchiveObject(with: sizeAsData) as! NSValue
					if album.path != nil
					{
						downloadCoverForAlbum(album, cropSize: cropSize.cgSizeValue) { (cover: UIImage, thumbnail: UIImage) in
							let cropped = thumbnail.smartCropped(toSize: cell.imageView.size)
							DispatchQueue.main.async {
								if let c = self.cellForItem(at: indexPath) as? MusicalEntityCollectionViewCell
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
									if let c = self.cellForItem(at: indexPath) as? MusicalEntityCollectionViewCell
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
			if myDelegate.isSearching(actively: true) //searching && searchBar.isFirstResponder == true
			{
				return
			}
			MusicDataSource.shared.getAlbumsForArtist(artist) {
				DispatchQueue.main.async {
					if let _ = self.cellForItem(at: indexPath) as? MusicalEntityCollectionViewCell
					{
						self.reloadItems(at: [indexPath])
					}
				}
			}
		}
	}

	private func _configureCellForPlaylist(_ cell: MusicalEntityCollectionViewCell, indexPath: IndexPath, playlist: Playlist)
	{
		cell.label.text = playlist.name
		cell.accessibilityLabel = playlist.name
		cell.image = generateCoverForPlaylist(playlist, size: cell.imageView.size)
	}
}

// MARK: - UICollectionViewDelegate
extension MusicalCollectionView : UICollectionViewDelegate
{
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
	{
		myDelegate.didSelectItem(indexPath: indexPath)
	}

	func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
	{
		if displayType != .albums
		{
			return
		}

		// When searching things can go wrong, this prevent some crashes
		let src = myDelegate.isSearching(actively: false) ? self.searchResults as! [Album] : items
		if indexPath.row >= src.count
		{
			return
		}

		// Remove download cover operation if still in queue
		let album = src[indexPath.row] as! Album
		let key = album.uniqueIdentifier
		if let op = _downloadOperations[key] as! CoverOperation?
		{
			_downloadOperations.removeValue(forKey: key)
			op.cancel()
			Logger.dlog("[+] Cancelling \(op)")
		}
	}
}
