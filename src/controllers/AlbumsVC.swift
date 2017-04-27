// AlbumsVC.swift
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


final class AlbumsVC : UIViewController
{
	// MARK: - Public properties
	@IBOutlet var collectionView: MusicalCollectionView!
	// Selected artist
	var artist: Artist!

	// MARK: - Private properties
	// Label in the navigationbar
	private var titleView: UILabel! = nil

	// MARK: - Initializers
	required init?(coder aDecoder: NSCoder)
	{
		self.artist = nil
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

		// CollectionView
		collectionView.myDelegate = self
		collectionView.displayType = .albums
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		if artist.albums.count <= 0
		{
			MusicDataSource.shared.getAlbumsForArtist(artist) {
				DispatchQueue.main.async {
					self.collectionView.items = self.artist.albums
					self.collectionView.reloadData()
					self.updateNavigationTitle()
				}
			}
		}
		else
		{
			DispatchQueue.main.async {
				self.collectionView.items = self.artist.albums
				self.collectionView.reloadData()
				self.updateNavigationTitle()
			}
		}

		updateNavigationTitle()
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
		if segue.identifier == "albums-to-albumdetail"
		{
			guard let indexes = collectionView.indexPathsForSelectedItems else
			{
				return
			}

			if let indexPath = indexes.first
			{
				let vc = segue.destination as! AlbumDetailVC
				vc.album = artist.albums[indexPath.row]
			}
		}
	}

	// MARK: - Private
	private func updateNavigationTitle()
	{
		let attrs = NSMutableAttributedString(string: artist.name + "\n", attributes: [NSFontAttributeName : UIFont(name: "HelveticaNeue-Medium", size: 14.0)!])
		attrs.append(NSAttributedString(string: "\(artist.albums.count) \(artist.albums.count == 1 ? NYXLocalizedString("lbl_album").lowercased() : NYXLocalizedString("lbl_albums").lowercased())", attributes: [NSFontAttributeName : UIFont(name: "HelveticaNeue", size: 13.0)!]))
		titleView.attributedText = attrs
	}
}

// MARK: - MusicalCollectionViewDelegate
extension AlbumsVC : MusicalCollectionViewDelegate
{
	func isSearching(actively: Bool) -> Bool
	{
		return false
	}

	func didSelectItem(indexPath: IndexPath)
	{
		performSegue(withIdentifier: "albums-to-albumdetail", sender: self)
	}
}
