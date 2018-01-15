// AlbumDetailVC_TVOS.swift
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


final class AlbumDetailVC_TVOS : UIViewController
{
	// MARK: - Public properties
	// Selected album
	var album: Album

	// MARK: - Private properties
	// Tableview for song list
	@IBOutlet private var tableView: UITableView! = nil
	// Cover
	@IBOutlet private var imageView: UIImageView! = nil
	// Album name
	@IBOutlet private var lblAlbum: UILabel! = nil
	// Artist
	@IBOutlet private var lblArtist: UILabel! = nil
	// Genre + year
	@IBOutlet private var lblGenre: UILabel! = nil

	// MARK: - Initializers
	required init?(coder aDecoder: NSCoder)
	{
		// Dummy
		self.album = Album(name: "")

		super.init(coder: aDecoder)
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()
		self.tableView.rowHeight = 80.0
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		// Get songs list if needed
		if let _ = album.tracks
		{
			updateInfos()
		}
		else
		{
			MusicDataSource.shared.getTracksForAlbums([album]) {
				DispatchQueue.main.async {
					self.updateInfos()
					self.tableView.reloadData()
				}
			}
		}
	}

	// MARK: - Private
	private func updateInfos()
	{
		// Set cover
		var image: UIImage? = nil
		if let coverURL = album.localCoverURL
		{
			if let cover = UIImage.loadFromFileURL(coverURL)
			{
				image = cover
			}
			else
			{
				let coverSize = NSKeyedUnarchiver.unarchiveObject(with: Settings.shared.data(forKey: kNYXPrefCoversSize)!) as! NSValue
				image = generateCoverForAlbum(album, size: coverSize.cgSizeValue)
			}
		}
		else
		{
			let coverSize = NSKeyedUnarchiver.unarchiveObject(with: Settings.shared.data(forKey: kNYXPrefCoversSize)!) as! NSValue
			image = generateCoverForAlbum(album, size: coverSize.cgSizeValue)
		}
		imageView.image = image

		if album.artist.count == 0
		{
			MusicDataSource.shared.getMetadatasForAlbum(album) {
				DispatchQueue.main.async {
					self.updateInfos()
				}
			}
		}

		lblAlbum.text = album.name
		lblArtist.text = album.artist
		lblGenre.text = album.genre
	}
}

// MARK: - UITableViewDelegate
extension AlbumDetailVC_TVOS : UITableViewDataSource
{
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if let tracks = album.tracks
		{
			return tracks.count
		}
		return 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "fr.whine.mpdremote.cell.track.tvos", for: indexPath) as! TrackTableViewCell_TVOS
		/*cell.contentView.backgroundColor = cell.backgroundColor
		cell.lblTitle.backgroundColor = cell.backgroundColor
		cell.lblTrack.backgroundColor = cell.backgroundColor
		cell.lblDuration.backgroundColor = cell.backgroundColor

		cell.lblTitle.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		cell.lblTrack.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		cell.lblDuration.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)*/

		let track = album.tracks![indexPath.row]
		cell.lblTrack.text = String(track.trackNumber)
		cell.lblTitle.text = track.name
		let minutes = track.duration.minutesRepresentation().minutes
		let seconds = track.duration.minutesRepresentation().seconds
		cell.lblDuration.text = "\(minutes):\(seconds < 10 ? "0" : "")\(seconds)"

		/*if PlayerController.shared.currentTrack == track
		{
			cell.lblTrack.font = UIFont(name: "HelveticaNeue-Bold", size: 10)
			cell.lblTitle.font = UIFont(name: "HelveticaNeue-CondensedBlack", size: 14)
			cell.lblDuration.font = UIFont(name: "HelveticaNeue-Medium", size: 10)
		}
		else
		{
			cell.lblTrack.font = UIFont(name: "HelveticaNeue", size: 10)
			cell.lblTitle.font = UIFont(name: "HelveticaNeue-Medium", size: 14)
			cell.lblDuration.font = UIFont(name: "HelveticaNeue-Light", size: 10)
		}*/

		return cell
	}
}

// MARK: - UITableViewDelegate
extension AlbumDetailVC_TVOS : UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		// Dummy cell
		guard let tracks = album.tracks else { return }
		if indexPath.row >= tracks.count
		{
			return
		}

		// Toggle play / pause for the current track
		if let currentPlayingTrack = PlayerController.shared.currentTrack
		{
			let selectedTrack = tracks[indexPath.row]
			if selectedTrack == currentPlayingTrack
			{
				PlayerController.shared.togglePause()
				return
			}
		}

		let b = tracks.filter({$0.trackNumber >= (indexPath.row + 1)})
		PlayerController.shared.playTracks(b, shuffle: Settings.shared.bool(forKey: kNYXPrefMPDShuffle), loop: Settings.shared.bool(forKey: kNYXPrefMPDRepeat))
	}
}
