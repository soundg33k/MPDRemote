// PlayerVC.swift
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
		UISlider.appearance().setThumbImage(UIImage(named:"slider-thumb"), forState:.Normal)
		sliderPosition.addTarget(self, action:#selector(changeTrackPositionAction(_:)), forControlEvents:.TouchUpInside)

		// Slider volume
		sliderVolume.value = Float(NSUserDefaults.standardUserDefaults().integerForKey(kNYXPrefVolume))
		sliderVolume.addTarget(self, action:#selector(changeVolumeAction(_:)), forControlEvents:.TouchUpInside)
		ivVolumeLo.image = UIImage(named:"img-volume-lo")?.imageTintedWithColor(UIColor.whiteColor())
		ivVolumeHi.image = UIImage(named:"img-volume-hi")?.imageTintedWithColor(UIColor.whiteColor())

		btnPlay.addTarget(MPDPlayer.shared, action:#selector(MPDPlayer.togglePause), forControlEvents:.TouchUpInside)

		btnNext.setImage(UIImage(named:"btn-next")?.imageTintedWithColor(UIColor.whiteColor()), forState:.Normal)
		btnNext.setImage(UIImage(named:"btn-next")?.imageTintedWithColor(UIColor.fromRGB(kNYXAppColor)), forState:.Highlighted)
		btnNext.addTarget(MPDPlayer.shared, action:#selector(MPDPlayer.requestNextTrack), forControlEvents:.TouchUpInside)

		btnPrevious.setImage(UIImage(named:"btn-previous")?.imageTintedWithColor(UIColor.whiteColor()), forState:.Normal)
		btnPrevious.setImage(UIImage(named:"btn-previous")?.imageTintedWithColor(UIColor.fromRGB(kNYXAppColor)), forState:.Highlighted)
		btnPrevious.addTarget(MPDPlayer.shared, action:#selector(MPDPlayer.requestPreviousTrack), forControlEvents:.TouchUpInside)

		let loop = NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRepeat)
		let imageRepeat = UIImage(named:"btn-repeat")
		btnRepeat.setImage(imageRepeat?.imageTintedWithColor(UIColor.fromRGB(0xCC0000))?.imageWithRenderingMode(.AlwaysOriginal), forState:.Normal)
		btnRepeat.setImage(imageRepeat?.imageTintedWithColor(UIColor.whiteColor())?.imageWithRenderingMode(.AlwaysOriginal), forState:.Selected)
		btnRepeat.selected = loop
		btnRepeat.addTarget(self, action:#selector(toggleRepeatAction(_:)), forControlEvents:.TouchUpInside)
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

		let random = NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRandom)
		let imageRandom = UIImage(named:"btn-random")
		btnRandom.setImage(imageRandom?.imageTintedWithColor(UIColor.fromRGB(0xCC0000))?.imageWithRenderingMode(.AlwaysOriginal), forState:.Normal)
		btnRandom.setImage(imageRandom?.imageTintedWithColor(UIColor.whiteColor())?.imageWithRenderingMode(.AlwaysOriginal), forState:.Selected)
		btnRandom.selected = random
		btnRandom.addTarget(self, action:#selector(toggleRandomAction(_:)), forControlEvents:.TouchUpInside)
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		coverView.makeTappable()
		coverView.makeLeftSwippable()
		coverView.makeRightSwippable()
		coverView.delegate = self
		// Useless motion effect
		var motionEffect = UIInterpolatingMotionEffect(keyPath:"center.x", type:.TiltAlongHorizontalAxis)
		motionEffect.minimumRelativeValue = 20.0
		motionEffect.maximumRelativeValue = -20.0
		coverView.addMotionEffect(motionEffect)
		motionEffect = UIInterpolatingMotionEffect(keyPath:"center.y", type:.TiltAlongVerticalAxis)
		motionEffect.minimumRelativeValue = 20.0
		motionEffect.maximumRelativeValue = -20.0
		coverView.addMotionEffect(motionEffect)
	}

	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)

		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(playingTrackNotification(_:)), name:kNYXNotificationCurrentPlayingTrack, object:nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(playingTrackChangedNotification(_:)), name:kNYXNotificationPlayingTrackChanged, object:nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(playerStatusChangedNotification(_:)), name:kNYXNotificationPlayerStatusChanged, object:nil)

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
					dispatch_async(dispatch_get_main_queue()) {
						self.coverView.image = cover
						iv?.image = cover
					}
				}
				APP_DELEGATE().operationQueue.addOperation(op)
			}
			else
			{
				MPDDataSource.shared.getPathForAlbum(album, callback: {
					let op = CoverOperation(album:album, cropSize:self.coverView.size)
					op.cplBlock = {(cover: UIImage, thumbnail: UIImage) in
						dispatch_async(dispatch_get_main_queue()) {
							self.coverView.image = cover
							iv?.image = cover
						}
					}
					APP_DELEGATE().operationQueue.addOperation(op)
				})
			}
		}

		_updatePlayPauseButton()
	}

	override func viewWillDisappear(animated: Bool)
	{
		super.viewWillDisappear(animated)

		NSNotificationCenter.defaultCenter().removeObserver(self, name:kNYXNotificationCurrentPlayingTrack, object:nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name:kNYXNotificationPlayingTrackChanged, object:nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name:kNYXNotificationPlayerStatusChanged, object:nil)
	}

	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
	{
		return .Portrait
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle
	{
		return .LightContent
	}

	override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation
	{
		return .Portrait
	}

	// MARK: - InteractableImageViewDelegate
	func didTap()
	{
		dismissViewControllerAnimated(true, completion:nil)
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
	func toggleRandomAction(sender: AnyObject?)
	{
		let prefs = NSUserDefaults.standardUserDefaults()
		let random = !prefs.boolForKey(kNYXPrefRandom)

		btnRandom.selected = random
		btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		prefs.setBool(random, forKey:kNYXPrefRandom)
		prefs.synchronize()

		MPDPlayer.shared.setRandom(random)
	}

	func toggleRepeatAction(sender: AnyObject?)
	{
		let prefs = NSUserDefaults.standardUserDefaults()
		let loop = !prefs.boolForKey(kNYXPrefRepeat)

		btnRepeat.selected = loop
		btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

		prefs.setBool(loop, forKey:kNYXPrefRepeat)
		prefs.synchronize()

		MPDPlayer.shared.setRepeat(loop)
	}

	func changeTrackPositionAction(sender: UISlider?)
	{
		if let track = MPDPlayer.shared.currentTrack
		{
			MPDPlayer.shared.setTrackPosition(Int(sliderPosition.value), trackPosition:track.position)
		}
	}

	func changeVolumeAction(sender: UISlider?)
	{
		let volume = Int(ceil(sliderVolume.value))
		let prefs = NSUserDefaults.standardUserDefaults()
		prefs.setInteger(volume, forKey:kNYXPrefVolume)
		prefs.synchronize()
		sliderVolume.accessibilityLabel = "\(NYXLocalizedString("lbl_volume")) \(volume)%"

		MPDPlayer.shared.setVolume(volume)
	}

	// MARK: - Notifications
	func playingTrackNotification(aNotification: NSNotification?)
	{
		guard let track = aNotification?.userInfo![kPlayerTrackKey] as? Track, let elapsed = aNotification?.userInfo![kPlayerElapsedKey] as? Int else
		{
			return
		}

		if !sliderPosition.selected && !sliderPosition.highlighted
		{
			sliderPosition.setValue(Float(elapsed), animated:true)
			sliderPosition.accessibilityLabel = "\(NYXLocalizedString("lbl_track_position")) : \(Int((sliderPosition.value * 100.0) / sliderPosition.maximumValue))%"
		}

		let elapsedDuration = Duration(seconds:UInt(elapsed))
		let remainingDuration = track.duration - elapsedDuration
		lblElapsedDuration.text = elapsedDuration.minutesRepresentationAsString()
		lblRemainingDuration.text = "-\(remainingDuration.minutesRepresentationAsString())"
	}

	func playingTrackChangedNotification(aNotification: NSNotification?)
	{
		guard let track = aNotification?.userInfo![kPlayerTrackKey] as? Track, let album = aNotification?.userInfo![kPlayerAlbumKey] as? Album else
		{
			return
		}
		lblTrackTitle.text = track.title
		lblTrackArtist.text = track.artist
		lblAlbumName.text = album.name
		sliderPosition.maximumValue = Float(track.duration.seconds)
	}

	func playerStatusChangedNotification(aNotification: NSNotification?)
	{
		_updatePlayPauseButton()
	}

	// MARK: - Private
	private func _updatePlayPauseButton()
	{
		if MPDPlayer.shared.status == .Paused
		{
			btnPlay.setImage(UIImage(named:"btn-play")?.imageTintedWithColor(UIColor.whiteColor()), forState:.Normal)
			btnPlay.setImage(UIImage(named:"btn-play")?.imageTintedWithColor(UIColor.fromRGB(kNYXAppColor)), forState:.Highlighted)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_play")
		}
		else
		{
			btnPlay.setImage(UIImage(named:"btn-pause")?.imageTintedWithColor(UIColor.whiteColor()), forState:.Normal)
			btnPlay.setImage(UIImage(named:"btn-pause")?.imageTintedWithColor(UIColor.fromRGB(kNYXAppColor)), forState:.Highlighted)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_pause")
		}
	}
}
