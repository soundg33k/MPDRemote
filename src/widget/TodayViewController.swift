// TodayViewController.swift
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
import NotificationCenter


final class TodayViewController: UIViewController, NCWidgetProviding
{
	// MARK: - Properties
	// Track title
	@IBOutlet private var lblTrackTitle: UILabel! = nil
	// Track artist name
	@IBOutlet private var lblTrackArtist: UILabel! = nil
	// Album name
	@IBOutlet private var lblAlbumName: UILabel! = nil
	// Play / pause button
	@IBOutlet private var btnPlay: UIButton! = nil
	// Previous track button
	@IBOutlet private var btnPrevious: UIButton! = nil
	// Next track button
	@IBOutlet private var btnNext: UIButton! = nil
	//
	private var canWork: Bool = true

    override func viewDidLoad()
	{
        super.viewDidLoad()

		btnNext.accessibilityLabel = NYXLocalizedString("lbl_next_track")
		btnPrevious.accessibilityLabel = NYXLocalizedString("lbl_previous_track")

		guard let serverAsData = Settings.shared.data(forKey: kNYXPrefMPDServer) else
		{
			self.disableAllBecauseCantWork()
			canWork = false
			return
		}

		do
		{
			let server = try JSONDecoder().decode(AudioServer.self, from: serverAsData)
			// Data source
			MusicDataSource.shared.server = server
			let resultDataSource = MusicDataSource.shared.initialize()
			if resultDataSource.succeeded == false
			{
				self.disableAllBecauseCantWork()
				canWork = false
			}
			MusicDataSource.shared.getListForDisplayType(.albums) {
			}

			// Player
			PlayerController.shared.server = server
			let resultPlayer = PlayerController.shared.initialize()
			if resultPlayer.succeeded == false
			{
				self.disableAllBecauseCantWork()
				canWork = false
			}
		}
		catch
		{
			self.disableAllBecauseCantWork()
			canWork = false
		}

		if canWork == true
		{
			NotificationCenter.default.addObserver(self, selector: #selector(playingTRackNotification(_:)), name: .currentPlayingTrack, object: nil)
		}
    }

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
	}

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void))
	{
		let ret = updateFields()
		completionHandler(ret == false ? NCUpdateResult.failed : NCUpdateResult.newData)
    }

	// MARK: - Actions
	@IBAction func togglePauseAction(_ sender: Any?)
	{
		PlayerController.shared.togglePause()
	}

	@IBAction func nextTrackAction(_ sender: Any?)
	{
		PlayerController.shared.requestNextTrack()
	}

	@IBAction func previousTrackAction(_ sender: Any?)
	{
		PlayerController.shared.requestPreviousTrack()
	}

	// MARK: - Private
	private func updateFields() -> Bool
	{
		var ret = true
		if let track = PlayerController.shared.currentTrack
		{
			lblTrackTitle.text = track.name
			lblTrackArtist.text = track.artist
		}
		else
		{
			ret = false
		}

		if let album = PlayerController.shared.currentAlbum
		{
			lblAlbumName.text = album.name
		}
		else
		{
			ret = false
		}

		if PlayerController.shared.currentStatus == .paused
		{
			let imgPlay = #imageLiteral(resourceName: "btn-play")
			btnPlay.setImage(imgPlay, for: .normal)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_play")
		}
		else
		{
			let imgPause = #imageLiteral(resourceName: "btn-pause")
			btnPlay.setImage(imgPause, for: .normal)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_pause")
		}

		return ret
	}

	private func disableAllBecauseCantWork()
	{
		btnPlay.isEnabled = false
		btnNext.isEnabled = false
		btnPrevious.isEnabled = false
		lblTrackTitle.text = "Error."
		lblTrackArtist.text = ""
		lblAlbumName.text = ""
	}

	// MARK: - Notification
	@objc private func playingTRackNotification(_ notification: Notification)
	{
		_ = self.updateFields()
	}
}
