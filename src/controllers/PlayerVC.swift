// PlayerVC.swift
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


final class PlayerVC : UIViewController, InteractableImageViewDelegate
{
	// MARK: - Private properties
	// Cover view
	@IBOutlet private var coverView: InteractableImageView! = nil
	// Track title
	@IBOutlet private var lblTrackTitle: UILabel! = nil
	// Track artist name
	@IBOutlet private var lblTrackArtist: UILabel! = nil
	// Album name
	@IBOutlet private var lblAlbumName: UILabel! = nil
	// Play/Pause button
	@IBOutlet private var btnPlay: UIButton! = nil
	// Next button
	@IBOutlet private var btnNext: UIButton! = nil
	// Previous button
	@IBOutlet private var btnPrevious: UIButton! = nil
	// Random button
	@IBOutlet private var btnRandom: UIButton! = nil
	// Repeat button
	@IBOutlet private var btnRepeat: UIButton! = nil
	// Progress bar
	@IBOutlet private var sliderPosition: UISlider! = nil
	// Track title
	@IBOutlet private var lblElapsedDuration: UILabel! = nil
	// Track artist name
	@IBOutlet private var lblRemainingDuration: UILabel! = nil
	// Volume control
	@IBOutlet private var sliderVolume: UISlider! = nil
	// Low volume image
	@IBOutlet private var ivVolumeLo: UIImageView! = nil
	// High volume image
	@IBOutlet private var ivVolumeHi: UIImageView! = nil

	// MARK: - UIViewController
	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Slider track position
		UISlider.appearance().setThumbImage(#imageLiteral(resourceName: "slider-thumb"), for:UIControlState())
		sliderPosition.addTarget(self, action:#selector(changeTrackPositionAction(_:)), for:.touchUpInside)

		// Slider volume
		sliderVolume.value = Float(UserDefaults.standard.integer(forKey: kNYXPrefVolume))
		sliderVolume.addTarget(self, action:#selector(changeVolumeAction(_:)), for:.touchUpInside)
		ivVolumeLo.image = #imageLiteral(resourceName: "img-volume-lo").imageTintedWithColor(#colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1))
		ivVolumeHi.image = #imageLiteral(resourceName: "img-volume-hi").imageTintedWithColor(#colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1))

		btnPlay.addTarget(MPDPlayer.shared, action:#selector(MPDPlayer.togglePause), for:.touchUpInside)

		btnNext.setImage(#imageLiteral(resourceName: "btn-next").imageTintedWithColor(#colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)), for:UIControlState())
		btnNext.setImage(#imageLiteral(resourceName: "btn-next").imageTintedWithColor(UIColor.fromRGB(kNYXAppColor)), for:.highlighted)
		btnNext.addTarget(MPDPlayer.shared, action:#selector(MPDPlayer.requestNextTrack), for:.touchUpInside)

		btnPrevious.setImage(#imageLiteral(resourceName: "btn-previous").imageTintedWithColor(#colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)), for:UIControlState())
		btnPrevious.setImage(#imageLiteral(resourceName: "btn-previous").imageTintedWithColor(UIColor.fromRGB(kNYXAppColor)), for:.highlighted)
		btnPrevious.addTarget(MPDPlayer.shared, action:#selector(MPDPlayer.requestPreviousTrack), for:.touchUpInside)

		let loop = UserDefaults.standard.bool(forKey: kNYXPrefRepeat)
		let imageRepeat = #imageLiteral(resourceName: "btn-repeat")
		btnRepeat.setImage(imageRepeat.imageTintedWithColor(UIColor.fromRGB(0xCC0000))?.withRenderingMode(.alwaysOriginal), for:UIControlState())
		btnRepeat.setImage(imageRepeat.imageTintedWithColor(#colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1))?.withRenderingMode(.alwaysOriginal), for:.selected)
		btnRepeat.isSelected = loop
		btnRepeat.addTarget(self, action:#selector(toggleRepeatAction(_:)), for:.touchUpInside)
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

		let random = UserDefaults.standard.bool(forKey: kNYXPrefRandom)
		let imageRandom = #imageLiteral(resourceName: "btn-random")
		btnRandom.setImage(imageRandom.imageTintedWithColor(UIColor.fromRGB(0xCC0000))?.withRenderingMode(.alwaysOriginal), for:UIControlState())
		btnRandom.setImage(imageRandom.imageTintedWithColor(#colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1))?.withRenderingMode(.alwaysOriginal), for:.selected)
		btnRandom.isSelected = random
		btnRandom.addTarget(self, action:#selector(toggleRandomAction(_:)), for:.touchUpInside)
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		coverView.makeTappable()
		coverView.makeLeftSwippable()
		coverView.makeRightSwippable()
		coverView.delegate = self
		// Useless motion effect
		var motionEffect = UIInterpolatingMotionEffect(keyPath:"center.x", type:.tiltAlongHorizontalAxis)
		motionEffect.minimumRelativeValue = 20.0
		motionEffect.maximumRelativeValue = -20.0
		coverView.addMotionEffect(motionEffect)
		motionEffect = UIInterpolatingMotionEffect(keyPath:"center.y", type:.tiltAlongVerticalAxis)
		motionEffect.minimumRelativeValue = 20.0
		motionEffect.maximumRelativeValue = -20.0
		coverView.addMotionEffect(motionEffect)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		NotificationCenter.default.addObserver(self, selector:#selector(playingTrackNotification(_:)), name:.currentPlayingTrack, object:nil)
		NotificationCenter.default.addObserver(self, selector:#selector(playingTrackChangedNotification(_:)), name:.playingTrackChanged, object:nil)
		NotificationCenter.default.addObserver(self, selector:#selector(playerStatusChangedNotification(_:)), name:.playerStatusChanged, object:nil)

		if let track = MPDPlayer.shared.currentTrack, let album = MPDPlayer.shared.currentAlbum
		{
			lblTrackTitle.text = track.title
			lblTrackArtist.text = track.artist
			lblAlbumName.text = album.name
			sliderPosition.maximumValue = Float(track.duration.seconds)
			let iv = view as? UIImageView

			if album.path != nil
			{
				let op = CoverOperation(album:album, cropSize:coverView.size)
				op.cplBlock = {(cover: UIImage, thumbnail: UIImage) in
					DispatchQueue.main.async {
						self.coverView.image = cover
						iv?.image = cover
					}
				}
				APP_DELEGATE().operationQueue.addOperation(op)
			}
			else
			{
				MPDDataSource.shared.getPathForAlbum(album) {
					let op = CoverOperation(album:album, cropSize:self.coverView.size)
					op.cplBlock = {(cover: UIImage, thumbnail: UIImage) in
						DispatchQueue.main.async {
							self.coverView.image = cover
							iv?.image = cover
						}
					}
					APP_DELEGATE().operationQueue.addOperation(op)
				}
			}
		}

		_updatePlayPauseButton()
	}

	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)

		NotificationCenter.default.removeObserver(self, name:.currentPlayingTrack, object:nil)
		NotificationCenter.default.removeObserver(self, name:.playingTrackChanged, object:nil)
		NotificationCenter.default.removeObserver(self, name:.playerStatusChanged, object:nil)
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask
	{
		return .portrait
	}

	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return .lightContent
	}

	override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation
	{
		return .portrait
	}

	// MARK: - InteractableImageViewDelegate
	func didTap()
	{
		dismiss(animated: true, completion:nil)
		MiniPlayerView.shared.stayHidden = false
		MiniPlayerView.shared.show()
	}
	func didSwipeLeft()
	{
		MPDPlayer.shared.requestNextTrack()
	}
	func didSwipeRight()
	{
		MPDPlayer.shared.requestPreviousTrack()
	}

	// MARK: - Buttons actions
	func toggleRandomAction(_ sender: AnyObject?)
	{
		let prefs = UserDefaults.standard
		let random = !prefs.bool(forKey: kNYXPrefRandom)

		btnRandom.isSelected = random
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		prefs.set(random, forKey:kNYXPrefRandom)
		prefs.synchronize()

		MPDPlayer.shared.setRandom(random)
	}

	func toggleRepeatAction(_ sender: AnyObject?)
	{
		let prefs = UserDefaults.standard
		let loop = !prefs.bool(forKey: kNYXPrefRepeat)

		btnRepeat.isSelected = loop
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

		prefs.set(loop, forKey:kNYXPrefRepeat)
		prefs.synchronize()

		MPDPlayer.shared.setRepeat(loop)
	}

	func changeTrackPositionAction(_ sender: UISlider?)
	{
		if let track = MPDPlayer.shared.currentTrack
		{
			MPDPlayer.shared.setTrackPosition(Int(sliderPosition.value), trackPosition:track.position)
		}
	}

	func changeVolumeAction(_ sender: UISlider?)
	{
		let volume = Int(ceil(sliderVolume.value))
		let prefs = UserDefaults.standard
		prefs.set(volume, forKey:kNYXPrefVolume)
		prefs.synchronize()
		sliderVolume.accessibilityLabel = "\(NYXLocalizedString("lbl_volume")) \(volume)%"

		MPDPlayer.shared.setVolume(volume)
	}

	// MARK: - Notifications
	func playingTrackNotification(_ aNotification: Notification?)
	{
		/*guard let track = (aNotification as NSNotification?)?.userInfo![kPlayerTrackKey] as? Track, let elapsed = (aNotification as NSNotification?)?.userInfo![kPlayerElapsedKey] as? Int else
		{
			return
		}*/
		guard let track = aNotification?.userInfo![kPlayerTrackKey] as? Track, let elapsed = aNotification?.userInfo![kPlayerElapsedKey] as? Int else
		{
			return
		}

		if !sliderPosition.isSelected && !sliderPosition.isHighlighted
		{
			sliderPosition.setValue(Float(elapsed), animated:true)
			sliderPosition.accessibilityLabel = "\(NYXLocalizedString("lbl_track_position")) : \(Int((sliderPosition.value * 100.0) / sliderPosition.maximumValue))%"
		}

		let elapsedDuration = Duration(seconds:UInt(elapsed))
		let remainingDuration = track.duration - elapsedDuration
		lblElapsedDuration.text = elapsedDuration.minutesRepresentationAsString()
		lblRemainingDuration.text = "-\(remainingDuration.minutesRepresentationAsString())"
	}

	func playingTrackChangedNotification(_ aNotification: Notification?)
	{
		guard let track = aNotification?.userInfo![kPlayerTrackKey] as? Track, let album = aNotification?.userInfo![kPlayerAlbumKey] as? Album else
		{
			return
		}
		/*guard let track = (aNotification as NSNotification?)?.userInfo![kPlayerTrackKey] as? Track, let album = (aNotification as NSNotification?)?.userInfo![kPlayerAlbumKey] as? Album else
		{
			return
		}*/
		lblTrackTitle.text = track.title
		lblTrackArtist.text = track.artist
		lblAlbumName.text = album.name
		sliderPosition.maximumValue = Float(track.duration.seconds)
	}

	func playerStatusChangedNotification(_ aNotification: Notification?)
	{
		_updatePlayPauseButton()
	}

	// MARK: - Private
	private func _updatePlayPauseButton()
	{
		if MPDPlayer.shared.status == .paused
		{
			let imgPlay = #imageLiteral(resourceName: "btn-play")
			btnPlay.setImage(imgPlay.imageTintedWithColor(#colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)), for:UIControlState())
			btnPlay.setImage(imgPlay.imageTintedWithColor(UIColor.fromRGB(kNYXAppColor)), for:.highlighted)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_play")
		}
		else
		{
			let imgPause = #imageLiteral(resourceName: "btn-pause")
			btnPlay.setImage(imgPause.imageTintedWithColor(#colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 1)), for:UIControlState())
			btnPlay.setImage(imgPause.imageTintedWithColor(UIColor.fromRGB(kNYXAppColor)), for:.highlighted)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_pause")
		}
	}
}
