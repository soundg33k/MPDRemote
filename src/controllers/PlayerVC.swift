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


final class PlayerVC : UIViewController
{
	// MARK: - Private properties
	// Cover view
	private var coverView: UIImageView! = nil
	// Track title
	private var lblTrackTitle: UILabel! = nil
	// Track artist name
	private var lblTrackArtist: UILabel! = nil
	// Album name
	private var lblAlbumName: UILabel! = nil
	// Play/Pause button
	private var btnPlay: UIButton! = nil
	// Next button
	private var btnNext: UIButton! = nil
	// Previous button
	private var btnPrevious: UIButton! = nil
	// Random button
	private var btnRandom: UIButton! = nil
	// Repeat button
	private var btnRepeat: UIButton! = nil
	// Progress bar
	private var sliderPosition: UISlider! = nil
	// Track title
	private var lblElapsedDuration: UILabel! = nil
	// Track artist name
	private var lblRemainingDuration: UILabel! = nil
	// Volume control
	private var sliderVolume: UISlider! = nil

	// MARK: - UIViewController
	override func loadView()
	{
		// Set an UIImageView as self.view
		let iv = UIImageView(frame:UIScreen.mainScreen().bounds)
		iv.contentMode = .ScaleToFill
		iv.userInteractionEnabled = true
		self.view = iv

		let blurEffect = UIBlurEffect(style:.Dark)
		let blurEffectView = UIVisualEffectView(effect:blurEffect)
		blurEffectView.frame = self.view.bounds
		self.view.addSubview(blurEffectView)

		// Track title
		self.lblTrackTitle = UILabel(frame:CGRect(0.0, 20.0, self.view.width, 20.0))
		self.lblTrackTitle.font = UIFont(name:"GillSans-Bold", size:15.0)
		self.lblTrackTitle.textAlignment = .Center
		self.lblTrackTitle.textColor = UIColor.whiteColor()
		blurEffectView.addSubview(self.lblTrackTitle)
		
		// Track title
		self.lblTrackArtist = UILabel(frame:CGRect(0.0, 40.0, self.view.width, 20.0))
		self.lblTrackArtist.font = UIFont(name:"GillSans", size:14.0)
		self.lblTrackArtist.textAlignment = .Center
		self.lblTrackArtist.textColor = UIColor.whiteColor()
		blurEffectView.addSubview(self.lblTrackArtist)
		
		// Track title
		self.lblAlbumName = UILabel(frame:CGRect(0.0, 60.0, self.view.width, 20.0))
		self.lblAlbumName.font = UIFont(name:"GillSans-Italic", size:13.0)
		self.lblAlbumName.textAlignment = .Center
		self.lblAlbumName.textColor = UIColor.whiteColor()
		blurEffectView.addSubview(self.lblAlbumName)
		
		// Cover view
		let width = self.view.width - 2 * 32.0
		self.coverView = UIImageView(frame:CGRect(32.0, self.lblAlbumName.bottom + 24.0, width, width))
		self.coverView.image = UIImage(named:"default-cover")
		self.coverView.userInteractionEnabled = true
		blurEffectView.addSubview(self.coverView)
		// Useless motion effect
		var motionEffect = UIInterpolatingMotionEffect(keyPath:"center.x", type:.TiltAlongHorizontalAxis)
		motionEffect.minimumRelativeValue = 20.0
		motionEffect.maximumRelativeValue = -20.0
		self.coverView.addMotionEffect(motionEffect)
		motionEffect = UIInterpolatingMotionEffect(keyPath:"center.y", type:.TiltAlongVerticalAxis)
		motionEffect.minimumRelativeValue = 20.0
		motionEffect.maximumRelativeValue = -20.0
		self.coverView.addMotionEffect(motionEffect)

		// Elapsed duration
		self.lblElapsedDuration = UILabel(frame:CGRect(self.coverView.x, self.coverView.bottom + 8.0, 40.0, 16.0))
		self.lblElapsedDuration.font = UIFont.systemFontOfSize(12.0)
		self.lblElapsedDuration.textAlignment = .Left
		self.lblElapsedDuration.textColor = UIColor.whiteColor()
		blurEffectView.addSubview(self.lblElapsedDuration)

		// Remaining duration
		self.lblRemainingDuration = UILabel(frame:CGRect(self.coverView.right - 40.0, self.coverView.bottom + 8.0, 40.0, 16.0))
		self.lblRemainingDuration.font = self.lblElapsedDuration.font
		self.lblRemainingDuration.textAlignment = .Right
		self.lblRemainingDuration.textColor = UIColor.whiteColor()
		blurEffectView.addSubview(self.lblRemainingDuration)

		// Position slider
		UISlider.appearance().setThumbImage(UIImage(named:"slider-thumb"), forState:.Normal)
		self.sliderPosition = UISlider(frame:CGRect(self.coverView.x, self.lblElapsedDuration.bottom, self.coverView.width, 16.0))
		self.sliderPosition.tintColor = UIColor.fromRGB(kNYXAppColor)
		self.sliderPosition.minimumValue = 0.0
		self.sliderPosition.addTarget(self, action:#selector(changeTrackPositionAction(_:)), forControlEvents:.TouchUpInside)
		blurEffectView.addSubview(self.sliderPosition)

		// Play button
		self.btnPlay = UIButton(type:.Custom)
		self.btnPlay.frame = CGRect((self.view.width - 44.0) * 0.5, self.sliderPosition.bottom + 16.0, 44.0, 44.0)
		self.btnPlay.addTarget(MPDPlayer.shared, action:#selector(MPDPlayer.togglePause), forControlEvents:.TouchUpInside)
		blurEffectView.addSubview(self.btnPlay)
		
		// Next button
		self.btnNext = UIButton(type:.Custom)
		self.btnNext.frame = CGRect(self.coverView.right - 44.0, self.sliderPosition.bottom + 16.0, 44.0, 44.0)
		self.btnNext.setImage(UIImage(named:"btn-next")?.imageTintedWithColor(UIColor.whiteColor()), forState:.Normal)
		self.btnNext.setImage(UIImage(named:"btn-next")?.imageTintedWithColor(UIColor.fromRGB(kNYXAppColor)), forState:.Highlighted)
		self.btnNext.addTarget(MPDPlayer.shared, action:#selector(MPDPlayer.requestNextTrack), forControlEvents:.TouchUpInside)
		self.btnNext.accessibilityLabel = NYXLocalizedString("lbl_next_track")
		blurEffectView.addSubview(self.btnNext)
		
		// Previous button
		self.btnPrevious = UIButton(type:.Custom)
		self.btnPrevious.frame = CGRect(self.coverView.x, self.sliderPosition.bottom + 16.0, 44.0, 44.0)
		self.btnPrevious.setImage(UIImage(named:"btn-previous")?.imageTintedWithColor(UIColor.whiteColor()), forState:.Normal)
		self.btnPrevious.setImage(UIImage(named:"btn-previous")?.imageTintedWithColor(UIColor.fromRGB(kNYXAppColor)), forState:.Highlighted)
		self.btnPrevious.addTarget(MPDPlayer.shared, action:#selector(MPDPlayer.requestPreviousTrack), forControlEvents:.TouchUpInside)
		self.btnPrevious.accessibilityLabel = NYXLocalizedString("lbl_previous_track")
		blurEffectView.addSubview(self.btnPrevious)

		// Volume slider
		let ivLo = UIImageView(frame:CGRect(self.coverView.x, self.btnPrevious.bottom + 12.0, 16.0, 16.0))
		ivLo.image = UIImage(named:"img-volume-lo")?.imageTintedWithColor(UIColor.whiteColor())
		blurEffectView.addSubview(ivLo)
		let ivHi = UIImageView(frame:CGRect(self.coverView.right - 16.0, self.btnPrevious.bottom + 12.0, 16.0, 16.0))
		ivHi.image = UIImage(named:"img-volume-hi")?.imageTintedWithColor(UIColor.whiteColor())
		blurEffectView.addSubview(ivHi)
		self.sliderVolume = UISlider(frame:CGRect(self.sliderPosition.x, ivHi.bottom + 4.0, self.sliderPosition.width, 16.0))
		self.sliderVolume.tintColor = UIColor.fromRGB(kNYXAppColor)
		self.sliderVolume.minimumValue = 0.0
		self.sliderVolume.maximumValue = 100.0
		self.sliderVolume.value = Float(NSUserDefaults.standardUserDefaults().integerForKey(kNYXPrefVolume))
		self.sliderVolume.addTarget(self, action:#selector(changeVolumeAction(_:)), forControlEvents:.TouchUpInside)
		self.sliderVolume.accessibilityLabel = "\(NYXLocalizedString("lbl_volume")) \(Int(self.sliderVolume.value))%"
		blurEffectView.addSubview(self.sliderVolume)

		// Random/repeat buttons
		let random = NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRandom)
		let imageRandom = UIImage(named:"btn-random")
		self.btnRandom = UIButton(type:.Custom)
		self.btnRandom.frame = CGRect(self.coverView.x - 12.0, self.view.height - 44.0, 44.0, 44.0)
		self.btnRandom.setImage(imageRandom?.imageTintedWithColor(UIColor.fromRGB(0xCC0000))?.imageWithRenderingMode(.AlwaysOriginal), forState:.Normal)
		self.btnRandom.setImage(imageRandom?.imageTintedWithColor(UIColor.whiteColor())?.imageWithRenderingMode(.AlwaysOriginal), forState:.Selected)
		self.btnRandom.selected = random
		self.btnRandom.addTarget(self, action:#selector(toggleRandomAction(_:)), forControlEvents:.TouchUpInside)
		self.btnRandom.accessibilityLabel = NYXLocalizedString(random ? "lbl_random_disable" : "lbl_random_enable")
		blurEffectView.addSubview(self.btnRandom)
		
		let loop = NSUserDefaults.standardUserDefaults().boolForKey(kNYXPrefRepeat)
		let imageRepeat = UIImage(named:"btn-repeat")
		self.btnRepeat = UIButton(type:.Custom)
		self.btnRepeat.frame = CGRect(self.coverView.right - 44.0 + 12.0, self.view.height - 44.0, 44.0, 44.0)
		self.btnRepeat.setImage(imageRepeat?.imageTintedWithColor(UIColor.fromRGB(0xCC0000))?.imageWithRenderingMode(.AlwaysOriginal), forState:.Normal)
		self.btnRepeat.setImage(imageRepeat?.imageTintedWithColor(UIColor.whiteColor())?.imageWithRenderingMode(.AlwaysOriginal), forState:.Selected)
		self.btnRepeat.selected = loop
		self.btnRepeat.addTarget(self, action:#selector(toggleRepeatAction(_:)), forControlEvents:.TouchUpInside)
		self.btnRepeat.accessibilityLabel = NYXLocalizedString(loop ? "lbl_repeat_disable" : "lbl_repeat_enable")
		blurEffectView.addSubview(self.btnRepeat)
		
		// Single tap on the image view to hide the view controller
		let singleTap = UITapGestureRecognizer(target:self, action:#selector(singleTap(_:)))
		singleTap.numberOfTapsRequired = 1
		singleTap.numberOfTouchesRequired = 1
		self.coverView.addGestureRecognizer(singleTap)

		// Swipe for previous / next tracks
		let swipeLeft = UISwipeGestureRecognizer(target:self, action:#selector(swipeLeft(_:)))
		swipeLeft.direction = .Left
		swipeLeft.numberOfTouchesRequired = 1
		self.coverView.addGestureRecognizer(swipeLeft)

		let swipeRight = UISwipeGestureRecognizer(target:self, action:#selector(swipeRight(_:)))
		swipeRight.direction = .Right
		swipeRight.numberOfTouchesRequired = 1
		self.coverView.addGestureRecognizer(swipeRight)
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

	// MARK: - Gestures
	func singleTap(gest: UITapGestureRecognizer)
	{
		self.dismissViewControllerAnimated(true, completion:nil)
		MiniPlayerView.shared.stayHidden = false
		MiniPlayerView.shared.show()
	}

	func swipeLeft(gest: UISwipeGestureRecognizer)
	{
		MPDPlayer.shared.requestNextTrack()
	}

	func swipeRight(gest: UISwipeGestureRecognizer)
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
		guard let elapsed = aNotification?.userInfo![kPlayerElapsedKey] as? Int else
		{
			return
		}
		guard let track = aNotification?.userInfo![kPlayerTrackKey] as? Track else
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
		guard let track = aNotification?.userInfo![kPlayerTrackKey] as? Track else
		{
			return
		}
		guard let album = aNotification?.userInfo![kPlayerAlbumKey] as? Album else
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
