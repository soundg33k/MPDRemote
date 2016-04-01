// MiniPlayerView.swift
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


public let playerViewHeight = CGFloat(44.0)


final class MiniPlayerView : UIView
{
	// MARK: - Properties
	// Singletion instance
	static let shared = MiniPlayerView(frame:CGRect(0.0, (UIApplication.sharedApplication().keyWindow?.frame.height)! + playerViewHeight, (UIApplication.sharedApplication().keyWindow?.frame.width)!, playerViewHeight))
	// Album cover
	private(set) var imageView: UIImageView!
	// Dummy acessible view for title
	private(set) var accessibleView: UIView!
	// Track title
	private(set) var lblTitle: UILabel!
	// Track artist
	private(set) var lblArtist: UILabel!
	// Play/pause button
	private(set) var btnPlayback: UIButton!
	// View to indicate track progression
	private(set) var progressView: UIView!
	// Visible flag
	private(set) var visible = false
	// Player should stay hidden, regardless of playback status
	var stayHidden = false

	// MARK: - Initializers
	override init(frame: CGRect)
	{
		super.init(frame:frame)
		self.backgroundColor = UIColor.clearColor()
		self.layer.shadowPath = UIBezierPath(rect:CGRect(-2.0, 5.0, frame.width + 4.0, 4.0)).CGPath
		self.layer.shadowRadius = 3.0
		self.layer.shadowOpacity = 1.0
		self.layer.shadowColor = UIColor.blackColor().CGColor
		self.layer.masksToBounds = false
		self.isAccessibilityElement = false

		let blurEffect = UIBlurEffect(style:.Light)
		let blurEffectView = UIVisualEffectView(effect:blurEffect)
		blurEffectView.frame = CGRect(CGPointZero, frame.size)
		self.addSubview(blurEffectView)

		self.imageView = UIImageView(frame:CGRect(0.0, 0.0, frame.height, frame.height))
		self.imageView.image = UIImage(named:"default-cover")
		blurEffectView.contentView.addSubview(self.imageView)

		// Vibrancy over the play/pause button
		let vibrancyEffectView = UIVisualEffectView(effect:UIVibrancyEffect(forBlurEffect:blurEffect))
		vibrancyEffectView.frame = CGRect(frame.right - frame.height, 0.0, 44.0, 44.0)
		blurEffectView.contentView.addSubview(vibrancyEffectView)

		self.btnPlayback = UIButton(type:.Custom)
		self.btnPlayback.frame = CGRect(0.0, 0.0, frame.height, frame.height)
		self.btnPlayback.setImage(UIImage(named:"btn-play"), forState:.Normal)
		self.btnPlayback.addTarget(self, action:#selector(MiniPlayerView.changePlaybackAction(_:)), forControlEvents:.TouchUpInside)
		self.btnPlayback.tag = PlayerStatus.Stopped.rawValue
		self.btnPlayback.isAccessibilityElement = true
		vibrancyEffectView.contentView.addSubview(self.btnPlayback)

		// Dummy accessibility view
		self.accessibleView = UIView(frame:CGRect(self.imageView.right, 0.0, vibrancyEffectView.left - self.imageView.right, frame.height))
		self.accessibleView.backgroundColor = UIColor.clearColor()
		self.accessibleView.isAccessibilityElement = true
		blurEffectView.contentView.addSubview(self.accessibleView)

		// Title
		self.lblTitle = UILabel(frame:CGRect(self.imageView.right + 5.0, 2.0, ((vibrancyEffectView.left + 5.0) - (self.imageView.right + 5.0)), 18.0))
		self.lblTitle.textAlignment = .Center
		self.lblTitle.font = UIFont(name:"GillSans-Bold", size:14.0)
		self.lblTitle.isAccessibilityElement = false
		blurEffectView.contentView.addSubview(self.lblTitle)

		// Artist
		self.lblArtist = UILabel(frame:CGRect(self.imageView.right + 5.0, self.lblTitle.bottom + 2.0, self.lblTitle.width, 16.0))
		self.lblArtist.textAlignment = .Center
		self.lblArtist.font = UIFont(name:"GillSans", size:12.0)
		self.lblArtist.isAccessibilityElement = false
		blurEffectView.contentView.addSubview(self.lblArtist)

		// Progress
		self.progressView = UIView(frame:CGRect(0.0, 0.0, 0.0, 1.0))
		self.progressView.isAccessibilityElement = false
		self.addSubview(self.progressView)

		// Single tap
		let tap = UITapGestureRecognizer(target:self, action:#selector(singleTap(_:)))
		tap.numberOfTapsRequired = 1
		tap.numberOfTouchesRequired = 1
		self.addGestureRecognizer(tap)

		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(MiniPlayerView.playingTrack(_:)), name:kNYXNotificationCurrentPlayingTrack, object:nil)

		let w = UIApplication.sharedApplication().keyWindow!
		w.addSubview(self)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Public
	func setInfoFromTrack(track: Track, ofAlbum album: Album)
	{
		self.lblTitle.text = track.title
		self.lblArtist.text = track.artist
		guard let url = album.localCoverURL else {return}
		if let image = UIImage(contentsOfFile:url.path!)
		{
			let x = KawaiiColors(image:image)
			x.analyze()
			self.progressView.backgroundColor = x.dominantColor
			self.imageView.image = image.imageScaledToFitSize(CGSize(self.imageView.width * UIScreen.mainScreen().scale, self.imageView.height * UIScreen.mainScreen().scale))
		}
		else
		{
			let sizeAsData = NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefCoverSize)!
			let cropSize = NSKeyedUnarchiver.unarchiveObjectWithData(sizeAsData) as! NSValue
			if album.path != nil
			{
				let op = DownloadCoverOperation(album:album, cropSize:cropSize.CGSizeValue())
				op.cplBlock = {(thumbnail: UIImage, cover: UIImage) in
					dispatch_async(dispatch_get_main_queue(), {
						self.setInfoFromTrack(track, ofAlbum:album)
					})
				}
				APP_DELEGATE().operationQueue.addOperation(op)
			}
			else
			{
				MPDDataSource.shared.findCoverPathForAlbum(album, callback:{
					let op = DownloadCoverOperation(album:album, cropSize:cropSize.CGSizeValue())
					op.cplBlock = {(thumbnail: UIImage, cover: UIImage) in
						dispatch_async(dispatch_get_main_queue(), {
							self.setInfoFromTrack(track, ofAlbum:album)
						})
					}
					APP_DELEGATE().operationQueue.addOperation(op)
				})
			}
		}
	}

	func show()
	{
		NSNotificationCenter.defaultCenter().postNotificationName(kNYXNotificationMiniPlayerViewWillShow, object:nil)
		let w = UIApplication.sharedApplication().keyWindow!
		UIView.animateWithDuration(0.35, delay:0.0, options:.CurveEaseInOut, animations:{
			self.y = w.frame.height - self.height
		}, completion: { finished in
			self.visible = true
		})
	}

	func hide()
	{
		NSNotificationCenter.defaultCenter().postNotificationName(kNYXNotificationMiniPlayerViewWillHide, object:nil)
		let w = UIApplication.sharedApplication().keyWindow!
		UIView.animateWithDuration(0.35, delay:0.0, options:.CurveEaseInOut, animations:{
			self.y = w.frame.height + self.height
		}, completion: { finished in
			self.visible = false
		})
	}

	func changePlaybackAction(sender: UIButton?)
	{
		if self.btnPlayback.tag == PlayerStatus.Playing.rawValue
		{
			let img = UIImage(named:"btn-play")!
			self.btnPlayback.setImage(img.imageWithRenderingMode(.AlwaysTemplate), forState:.Normal)
			self.btnPlayback.accessibilityLabel = NYXLocalizedString("lbl_play")
		}
		else
		{
			let img = UIImage(named:"btn-pause")!
			self.btnPlayback.setImage(img.imageWithRenderingMode(.AlwaysTemplate), forState:.Normal)
			self.btnPlayback.accessibilityLabel = NYXLocalizedString("lbl_pause")
		}
		MPDPlayer.shared.togglePausePlayback()
	}

	// MARK: - Private
	func singleTap(gest: UITapGestureRecognizer)
	{
		NSNotificationCenter.defaultCenter().postNotificationName(kNYXNotificationMiniPlayerShouldExpand, object:nil)
	}

	// MARK: - Notifications
	func playingTrack(aNotification: NSNotification)
	{
		if let infos = aNotification.userInfo
		{
			if !self.visible && !self.stayHidden
			{
				self.show()
			}

			let track = infos[kPlayerTrackKey] as! Track
			let album = infos[kPlayerAlbumKey] as! Album
			let elapsed = infos[kPlayerElapsedKey] as! Int
			let state = PlayerStatus(rawValue:infos[kPlayerStatusKey] as! Int)!
			if state == .Playing
			{
				let img = UIImage(named:"btn-pause")
				self.btnPlayback.setImage(img, forState:.Normal)
				self.btnPlayback.accessibilityLabel = NYXLocalizedString("lbl_pause")
			}
			else
			{
				let img = UIImage(named:"btn-play")
				self.btnPlayback.setImage(img, forState:.Normal)
				self.btnPlayback.accessibilityLabel = NYXLocalizedString("lbl_play")
			}
			self.btnPlayback.tag = state.rawValue

			if track.title != self.lblTitle.text
			{
				self.setInfoFromTrack(track, ofAlbum:album)
			}

			let ratio = self.width / CGFloat(track.duration.seconds)
			UIView.animateWithDuration(0.5, animations:{
				self.progressView.width = ratio * CGFloat(elapsed)
			})
			self.accessibleView.accessibilityLabel = "\(track.title) \(NYXLocalizedString("lbl_by")) \(track.artist)\n\((100 * elapsed) / Int(track.duration.seconds))% \(NYXLocalizedString("lbl_played"))"
		}
	}
}
