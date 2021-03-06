// PlaylistsTVC.swift
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


final class PlaylistsTVC : UITableViewController
{
	// List of artists
	var playlists = [Playlist]()
	// Track to add
	var trackToAdd: Track? = nil

	// MARK: - Initializers
	init()
	{
		super.init(style: .plain)
	}

	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()
		self.navigationController?.navigationBar.isTranslucent = false
		self.navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
		self.navigationController?.navigationBar.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
		self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)]
		self.navigationItem.title = NYXLocalizedString("lbl_playlists")

		tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "fr.whine.mpdremote.cell.playlist")
		tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

		// Create playlist button
		let createButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn-add"), style: .plain, target: self, action: #selector(createPlaylistAction(_:)))
		createButton.accessibilityLabel = NYXLocalizedString("lbl_create_playlist")
		navigationItem.rightBarButtonItems = [createButton]
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		getPlaylists()
	}

	// MARK: - Actions
	@objc func createPlaylistAction(_ sender: Any?)
	{
		let alertController = UIAlertController(title: NYXLocalizedString("lbl_create_playlist_name"), message: nil, preferredStyle: .alert)

		alertController.addAction(UIAlertAction(title: "Save", style: .default, handler: { alert -> Void in
			let textField = alertController.textFields![0] as UITextField

			if String.isNullOrWhiteSpace(textField.text)
			{
				let errorAlert = UIAlertController(title: NYXLocalizedString("lbl_error"), message: NYXLocalizedString("lbl_playlist_create_emptyname"), preferredStyle: .alert)
				errorAlert.addAction(UIAlertAction(title: NYXLocalizedString("lbl_ok"), style: .cancel, handler: { alert -> Void in
				}))
				self.present(errorAlert, animated: true, completion: nil)
			}
			else
			{
				MusicDataSource.shared.createPlaylist(name: textField.text!) { (result: ActionResult<Void>) in
					if result.succeeded
					{
						MusicDataSource.shared.getListForDisplayType(.playlists) {
							DispatchQueue.main.async {
								self.getPlaylists()
							}
						}
					}
					else
					{
						DispatchQueue.main.async {
							MessageView.shared.showWithMessage(message: result.messages.first!)
						}
					}
				}
			}
		}))
		alertController.addAction(UIAlertAction(title: NYXLocalizedString("lbl_cancel"), style: .cancel, handler: nil))

		alertController.addTextField(configurationHandler: { (textField) -> Void in
			textField.placeholder = NYXLocalizedString("lbl_create_playlist_placeholder")
			textField.textAlignment = .left
		})

		self.present(alertController, animated: true, completion: nil)
	}

	// MARK: - Private
	private func getPlaylists()
	{
		MusicDataSource.shared.getListForDisplayType(.playlists) {
			DispatchQueue.main.async {
				self.playlists = MusicDataSource.shared.playlists
				self.tableView.reloadData()
			}
		}
	}
}

// MARK: - UITableViewDataSource
extension PlaylistsTVC
{
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return playlists.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "fr.whine.mpdremote.cell.playlist", for: indexPath)

		let playlist = playlists[indexPath.row]

		cell.textLabel?.text = playlist.name
		cell.textLabel?.isAccessibilityElement = false
		cell.accessibilityLabel = playlist.name

		return cell
	}
}

// MARK: - UITableViewDelegate
extension PlaylistsTVC
{
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
			tableView.deselectRow(at: indexPath, animated: true)
		})

		guard let track = trackToAdd else
		{
			return
		}

		let playlist = playlists[indexPath.row]

		MusicDataSource.shared.addTrackToPlaylist(playlist: playlist, track: track) { (result: ActionResult<Void>) in
			DispatchQueue.main.async {
				if result.succeeded
				{
					let str = "\(track.name) \(NYXLocalizedString("lbl_playlist_track_added")) \(playlist.name)"
					MessageView.shared.showWithMessage(message: Message(content: str, type: .success))
				}
				else
				{
					MessageView.shared.showWithMessage(message: result.messages.first!)
				}
			}
		}
	}
}
