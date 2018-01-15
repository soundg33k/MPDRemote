// LibraryTV_VC.swift
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


final class CollectionFlowLayout : UICollectionViewFlowLayout
{
	let sideSpan = CGFloat(50.0)
	let columns = 5
	var collectionViewWidth: CGFloat

	override init()
	{
		self.collectionViewWidth = UIScreen.main.bounds.width
		super.init()
		setupLayout()
	}

	init(width: CGFloat)
	{
		self.collectionViewWidth = width
		super.init()
		setupLayout()
	}

	required init?(coder aDecoder: NSCoder)
	{
		self.collectionViewWidth = UIScreen.main.bounds.width
		super.init(coder: aDecoder)
		setupLayout()
	}

	func setupLayout()
	{
		self.sectionInset = UIEdgeInsets(top: sideSpan, left: sideSpan, bottom: sideSpan, right: sideSpan)
		scrollDirection = .vertical
	}

	private func itemWidth() -> CGFloat
	{
		return ceil((self.collectionViewWidth / CGFloat(columns)) - (2 * sideSpan))
	}

	override var itemSize: CGSize
		{
		set
		{
			self.itemSize = CGSize(itemWidth(), itemWidth() + 24.0)
		}
		get
		{
			return CGSize(itemWidth(), itemWidth() + 24.0)
		}
	}

	override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint
	{
		return collectionView!.contentOffset
	}
}

final class LibraryVC_TVOS : UIViewController
{
	// MARK: - Properties
	//
	@IBOutlet private var collectionView: UICollectionView!
	//
	private var _serverChanged: Bool = false
	// Cover download operations
	private var _downloadOperations = [String : Operation]()

	override func viewDidLoad()
	{
		super.viewDidLoad()
		self.tabBarItem.title = NYXLocalizedString("lbl_section_home")

		let layout = CollectionFlowLayout(width: self.collectionView.bounds.width)
		self.collectionView.collectionViewLayout.invalidateLayout()
		self.collectionView.setCollectionViewLayout(layout, animated: false)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		// Initialize the mpd connection
		if MusicDataSource.shared.server == nil
		{
			if let serverAsData = Settings.shared.data(forKey: kNYXPrefMPDServer)
			{
				do
				{
					let server = try JSONDecoder().decode(AudioServer.self, from: serverAsData)
					// Data source
					MusicDataSource.shared.server = server
					let resultDataSource = MusicDataSource.shared.initialize()
					if resultDataSource.succeeded == false
					{
						//MessageView.shared.showWithMessage(message: resultDataSource.messages.first!)
					}
					if MusicDataSource.shared.displayType != .albums
					{
						// Always fetch the albums list
						MusicDataSource.shared.getListForDisplayType(.albums) {}
					}
					MusicDataSource.shared.getListForDisplayType(MusicDataSource.shared.displayType) {
						DispatchQueue.main.async {
							//self.collectionView.items = MusicDataSource.shared.selectedList()
							//self.collectionView.displayType = self._displayType
							self.collectionView.reloadData()
						}
					}

					// Player
					PlayerController.shared.server = server
					let resultPlayer = PlayerController.shared.initialize()
					if resultPlayer.succeeded == false
					{
						//MessageView.shared.showWithMessage(message: resultPlayer.messages.first!)
					}
				}
				catch
				{
					let alertController = UIAlertController(title: NYXLocalizedString("lbl_alert_servercfg_error"), message:NYXLocalizedString("lbl_alert_server_need_check"), preferredStyle: .alert)
					let cancelAction = UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel, handler: nil)
					alertController.addAction(cancelAction)
					present(alertController, animated: true, completion: nil)
				}
			}
			else
			{
				Logger.shared.log(type: .debug, message: "No MPD server registered yet")
				//containerDelegate?.showServerVC()
			}
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
			MusicDataSource.shared.getListForDisplayType(MusicDataSource.shared.displayType) {
				DispatchQueue.main.async {
					//self.collectionView.items = MusicDataSource.shared.selectedList()
					//self.collectionView.displayType = self._displayType
					self.collectionView.reloadData()
					self.collectionView.setContentOffset(.zero, animated: false) // Scroll to top
				}
			}

			// First time config case
			if PlayerController.shared.server == nil
			{
				PlayerController.shared.server = MusicDataSource.shared.server
				let result = PlayerController.shared.reinitialize()
				if result.succeeded == false
				{
					//MessageView.shared.showWithMessage(message: result.messages.first!)
				}
			}

			_serverChanged = false
		}
	}

	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)

		OperationManager.shared.cancelAllOperations()
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
		super.prepare(for: segue, sender: sender)

		if segue.identifier == "library-to-albumdetail"
		{
			let row = collectionView.indexPathsForSelectedItems![0].row
			let album = MusicDataSource.shared.albums[row]
			let vc = segue.destination as! AlbumDetailVC_TVOS
			vc.album = album
		}
	}

	// MARK: - Private
	private func downloadCoverForAlbum(_ album: Album, cropSize: CGSize, callback:((_ cover: UIImage, _ thumbnail: UIImage) -> Void)?) -> CoverOperation
	{
		let key = album.uniqueIdentifier
		if let cop = _downloadOperations[key] as! CoverOperation?
		{
			return cop
		}
		let downloadOperation = CoverOperation(album: album, cropSize: cropSize)
		weak var weakOperation = downloadOperation
		downloadOperation.callback = {(cover: UIImage, thumbnail: UIImage) in
			if let _ = weakOperation
			{
				self._downloadOperations.removeValue(forKey: key)
			}
			if let block = callback
			{
				block(cover, thumbnail)
			}
		}
		_downloadOperations[key] = downloadOperation

		OperationManager.shared.addOperation(downloadOperation)

		return downloadOperation
	}
}

// MARK: - UICollectionViewDataSource
extension LibraryVC_TVOS : UICollectionViewDataSource
{
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		return MusicDataSource.shared.selectedList().count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
	{
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fr.whine.mpdremote.cell.musicalentity.tvos", for: indexPath) as! CollectionViewCell
		cell.layer.shouldRasterize = true
		cell.layer.rasterizationScale = UIScreen.main.scale

		let entity = MusicDataSource.shared.selectedList()[indexPath.row]
		// Init cell
		cell.label.text = entity.name
		cell.accessibilityLabel = entity.name
		cell.image = nil
		switch MusicDataSource.shared.displayType
		{
		case .albums:
			_handleCoverForCell(cell, at: indexPath, withAlbum: entity as! Album)
		case .artists:
			_configureCellForArtist(cell, indexPath: indexPath, artist: entity as! Artist)
		case .albumsartists:
			_configureCellForArtist(cell, indexPath: indexPath, artist: entity as! Artist)
		case .genres:
			_configureCellForGenre(cell, indexPath: indexPath, genre: entity as! Genre)
		case .playlists:
			cell.image = generateCoverForPlaylist(entity as! Playlist, size: cell.imageView.size)
		}

		return cell
	}

	private func _configureCellForGenre(_ cell: CollectionViewCell, indexPath: IndexPath, genre: Genre)
	{
		if let album = genre.albums.first
		{
			_handleCoverForCell(cell, at: indexPath, withAlbum: album)
		}
		else
		{
			MusicDataSource.shared.getAlbumsForGenre(genre, firstOnly: true) {
				if let album = genre.albums.first
				{
					DispatchQueue.main.async {
						if let c = self.collectionView.cellForItem(at: indexPath) as? CollectionViewCell
						{
							self._handleCoverForCell(c, at: indexPath, withAlbum: album)
						}
					}
				}
			}
			return
		}
	}

	private func _configureCellForArtist(_ cell: CollectionViewCell, indexPath: IndexPath, artist: Artist)
	{
		if let album = artist.albums.first
		{
			_handleCoverForCell(cell, at: indexPath, withAlbum: album)
		}
		else
		{
			MusicDataSource.shared.getAlbumsForArtist(artist, isAlbumArtist: MusicDataSource.shared.displayType == .albumsartists) {
				if let album = artist.albums.first
				{
					DispatchQueue.main.async {
						if let c = self.collectionView.cellForItem(at: indexPath) as? CollectionViewCell
						{
							self._handleCoverForCell(c, at: indexPath, withAlbum: album)
						}
					}
				}
			}
		}
	}

	private func _handleCoverForCell(_ cell: CollectionViewCell, at indexPath: IndexPath, withAlbum album: Album)
	{
		// If image is in cache, bail out quickly
		if let cachedImage = ImageCache.shared[album.uniqueIdentifier]
		{
			cell.image = cachedImage
			return
		}

		// Get local URL for cover
		guard let _ = Settings.shared.data(forKey: kNYXPrefWEBServer) else { return }
		guard let coverURL = album.localCoverURL else
		{
			Logger.shared.log(type: .error, message: "No cover file URL for \(album)") // should not happen
			return
		}

		if let cover = UIImage.loadFromFileURL(coverURL)
		{
			cell.image = cover
			ImageCache.shared[album.uniqueIdentifier] = cover
		}
		else
		{
			let sizeAsData = Settings.shared.data(forKey: kNYXPrefCoversSizeTVOS)!
			let cropSize = NSKeyedUnarchiver.unarchiveObject(with: sizeAsData) as! NSValue
			if album.path != nil
			{
				_ = downloadCoverForAlbum(album, cropSize: cropSize.cgSizeValue) { (cover: UIImage, thumbnail: UIImage) in
					DispatchQueue.main.async {
						if let c = self.collectionView.cellForItem(at: indexPath) as? CollectionViewCell
						{
							c.image = thumbnail
						}
					}
				}
			}
			else
			{
				MusicDataSource.shared.getPathForAlbum(album) {
					_ = self.downloadCoverForAlbum(album, cropSize: cropSize.cgSizeValue) { (cover: UIImage, thumbnail: UIImage) in
						DispatchQueue.main.async {
							if let c = self.collectionView.cellForItem(at: indexPath) as? CollectionViewCell
							{
								c.image = thumbnail
							}
						}
					}
				}
			}
		}
	}
}

// MARK: - UICollectionViewDelegate
extension LibraryVC_TVOS : UICollectionViewDelegate
{
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
	{
		performSegue(withIdentifier: "library-to-albumdetail", sender: self)
	}
}
