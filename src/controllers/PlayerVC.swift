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
		self.sliderPosition.addTarget(self, action:#selector(changeTrackPositionAction(_:)), forControlEvents:.TouchUpInside)

		// Slider volume
		self.sliderVolume.value = Float(NSUserDefaults.standardUserDefaults().integerForKey(kNYXPrefVolume))
		self.sliderVolume.addTarget(self, action:#selector(changeVolumeAction(_:)), forControlEvents:.TouchUpInside)
		ivVolumeLo.image = UIImage(named:"img-volume-lo")?.imageTintedWithColor(UIColor.whiteColor())
		ivVolumeHi.image = UIImage(named:"img-volume-hi")?.imageTintedWithColor(UIColor.whiteColor())

		self.btnPlay.addTarget(MPDPlayer.shared, action:#selector(MPDPlayer.togglePause), forControlEvents:.TouchUpInside)

		self.btnNext.setImage(UIImage(named:"btn-next")?.imageTintedWithColor(UIColor.whiteColor()), forState:.Normal)
		self.btnNext.setImage(UIImage(named:"btn-next")?.imageTintedWithColor(UIColor.fromRGB(kNYXAppColor)), forState:.Highlighted)
		self.btnNext.addTarget(MPDPlayer.shared, action:#selector(MPDPlayer.requestNextTrack), forControlEvents:.TouchUpInside)

		self.btnPrevious.setImage(UIImage(named:"btn-previous")?.imageTintedWithColor(UIColor.whiteColor()), forState:.Normal)
		self.btnPrevious.setImage(UIImage(named:"btn-previous")?.imageTintedWithColor(UIColor.fromRGB(kNYXAppColor)), forState:.Highlighted)
		self.btnPrevious.addTarget(MPDPlayer.shared, action:#selector(MPDPlayer.requestPreviousTrack), forControlEvents:.TouchUpInside)

		let loop = NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRepeat)
		let imageRepeat = UIImage(named:"btn-repeat")
		self.btnRepeat.setImage(imageRepeat?.imageTintedWithColor(UIColor.fromRGB(0xCC0000))?.imageWithRenderingMode(.AlwaysOriginal), forState:.Normal)
		self.btnRepeat.setImage(imageRepeat?.imageTintedWithColor(UIColor.whiteColor())?.imageWithRenderingMode(.AlwaysOriginal), forState:.Selected)
		self.btnRepeat.selected = loop
		self.btnRepeat.addTarget(self, action:#selector(toggleRepeatAction(_:)), forControlEvents:.TouchUpInside)
		self.btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

		let random = NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRandom)
		let imageRandom = UIImage(named:"btn-random")
		self.btnRandom.setImage(imageRandom?.imageTintedWithColor(UIColor.fromRGB(0xCC0000))?.imageWithRenderingMode(.AlwaysOriginal), forState:.Normal)
		self.btnRandom.setImage(imageRandom?.imageTintedWithColor(UIColor.whiteColor())?.imageWithRenderingMode(.AlwaysOriginal), forState:.Selected)
		self.btnRandom.selected = random
		self.btnRandom.addTarget(self, action:#selector(toggleRandomAction(_:)), forControlEvents:.TouchUpInside)
		self.btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		self.coverView.makeTappable()
		self.coverView.makeLeftSwippable()
		self.coverView.makeRightSwippable()
		self.coverView.delegate = self
		// Useless motion effect
		var motionEffect = UIInterpolatingMotionEffect(keyPath:"center.x", type:.TiltAlongHorizontalAxis)
		motionEffect.minimumRelativeValue = 20.0
		motionEffect.maximumRelativeValue = -20.0
		self.coverView.addMotionEffect(motionEffect)
		motionEffect = UIInterpolatingMotionEffect(keyPath:"center.y", type:.TiltAlongVerticalAxis)
		motionEffect.minimumRelativeValue = 20.0
		motionEffect.maximumRelativeValue = -20.0
		self.coverView.addMotionEffect(motionEffect)
	}

	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)

		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(playingTrackNotification(_:)), name:kNYXNotificationCurrentPlayingTrack, object:nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(playingTrackChangedNotification(_:)), name:kNYXNotificationPlayingTrackChanged, object:nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(playerStatusChangedNotification(_:)), name:kNYXNotificationPlayerStatusChanged, object:nil)

		if let track = MPDPlayer.shared.currentTrack, let album = MPDPlayer.shared.currentAlbum
		{
			self.lblTrackTitle.text = track.title
			self.lblTrackArtist.text = track.artist
			self.lblAlbumName.text = album.name
			self.sliderPosition.maximumValue = Float(track.duration.seconds)
			let iv = self.view as? UIImageView

			if album.path != nil
			{
				let op = DownloadCoverOperation(album:album, cropSize:self.coverView.size)
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
					let op = DownloadCoverOperation(album:album, cropSize:self.coverView.size)
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

		self._updatePlayPauseButton()
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
		self.dismissViewControllerAnimated(true, completion:nil)
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

		self.btnRandom.selected = random
		self.btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")

		prefs.setBool(random, forKey:kNYXPrefRandom)
		prefs.synchronize()

		MPDPlayer.shared.setRandom(random)
	}

	func toggleRepeatAction(sender: AnyObject?)
	{
		let prefs = NSUserDefaults.standardUserDefaults()
		let loop = !prefs.boolForKey(kNYXPrefRepeat)

		self.btnRepeat.selected = loop
		self.btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")

		prefs.setBool(loop, forKey:kNYXPrefRepeat)
		prefs.synchronize()

		MPDPlayer.shared.setRepeat(loop)
	}

	func changeTrackPositionAction(sender: UISlider?)
	{
		if let track = MPDPlayer.shared.currentTrack
		{
			MPDPlayer.shared.setTrackPosition(Int(self.sliderPosition.value), trackPosition:track.position)
		}
	}

	func changeVolumeAction(sender: UISlider?)
	{
		let volume = Int(ceil(self.sliderVolume.value))
		let prefs = NSUserDefaults.standardUserDefaults()
		prefs.setInteger(volume, forKey:kNYXPrefVolume)
		prefs.synchronize()
		self.sliderVolume.accessibilityLabel = "\(NYXLocalizedString("lbl_volume")) \(volume)%"

		MPDPlayer.shared.setVolume(volume)
	}

	// MARK: - Notifications
	func playingTrackNotification(aNotification: NSNotification?)
	{
		guard let track = aNotification?.userInfo![kPlayerTrackKey] as? Track, let elapsed = aNotification?.userInfo![kPlayerElapsedKey] as? Int else
		{
			return
		}

		if !self.sliderPosition.selected && !self.sliderPosition.highlighted
		{
			self.sliderPosition.setValue(Float(elapsed), animated:true)
			self.sliderPosition.accessibilityLabel = "\(NYXLocalizedString("lbl_track_position")) : \(Int((self.sliderPosition.value * 100.0) / self.sliderPosition.maximumValue))%"
		}

		let elapsedDuration = Duration(seconds:UInt(elapsed))
		let remainingDuration = track.duration - elapsedDuration
		self.lblElapsedDuration.text = elapsedDuration.minutesRepresentationAsString()
		self.lblRemainingDuration.text = "-\(remainingDuration.minutesRepresentationAsString())"
	}

	func playingTrackChangedNotification(aNotification: NSNotification?)
	{
		guard let track = aNotification?.userInfo![kPlayerTrackKey] as? Track, let album = aNotification?.userInfo![kPlayerAlbumKey] as? Album else
		{
			return
		}
		self.lblTrackTitle.text = track.title
		self.lblTrackArtist.text = track.artist
		self.lblAlbumName.text = album.name
		self.sliderPosition.maximumValue = Float(track.duration.seconds)
	}

	func playerStatusChangedNotification(aNotification: NSNotification?)
	{
		self._updatePlayPauseButton()
	}

	// MARK: - Private
	private func _updatePlayPauseButton()
	{
		if MPDPlayer.shared.status == .Paused
		{
			self.btnPlay.setImage(UIImage(named:"btn-play")?.imageTintedWithColor(UIColor.whiteColor()), forState:.Normal)
			self.btnPlay.setImage(UIImage(named:"btn-play")?.imageTintedWithColor(UIColor.fromRGB(kNYXAppColor)), forState:.Highlighted)
			self.btnPlay.accessibilityLabel = NYXLocalizedString("lbl_play")
		}
		else
		{
			self.btnPlay.setImage(UIImage(named:"btn-pause")?.imageTintedWithColor(UIColor.whiteColor()), forState:.Normal)
			self.btnPlay.setImage(UIImage(named:"btn-pause")?.imageTintedWithColor(UIColor.fromRGB(kNYXAppColor)), forState:.Highlighted)
			self.btnPlay.accessibilityLabel = NYXLocalizedString("lbl_pause")
		}
	}
}
