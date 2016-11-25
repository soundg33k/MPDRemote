// MiniPlayerView.swift
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


public let playerViewHeight = CGFloat(44.0)


final class MiniPlayerView : UIView, PTappable
{
	// MARK: - Public properties
	// Singletion instance
	static let shared = MiniPlayerView(frame: CGRect(0.0, (UIApplication.shared.keyWindow?.frame.height)! + playerViewHeight, (UIApplication.shared.keyWindow?.frame.width)!, playerViewHeight))
	// Visible flag
	private(set) var visible = false
	// Player should stay hidden, regardless of playback status
	var stayHidden = false
	// Album cover
	private(set) var imageView: UIImageView!

	// MARK: - Private properties
	fileprivate var blurEffectView: UIVisualEffectView!

	// Dummy acessible view for title
	private var accessibleView: UIView!
	// Track title
	private var lblTitle: UILabel!
	// Track artist
	private var lblArtist: UILabel!
	// Play/pause button
	private var btnPlay: UIButton!
	// View to indicate track progression
	private var progressView: UIView!

	// MARK: - Initializers
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		self.backgroundColor = #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 0)

		// Top shadow
		self.layer.shadowPath = UIBezierPath(rect: CGRect(-2.0, 5.0, frame.width + 4.0, 4.0)).cgPath
		self.layer.shadowRadius = 3.0
		self.layer.shadowOpacity = 1.0
		self.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
		self.layer.masksToBounds = false
		self.isAccessibilityElement = false

		// Blur background
		let blurEffect = UIBlurEffect(style: isNightModeEnabled() ? .dark : .light)
		self.blurEffectView = UIVisualEffectView(effect: blurEffect)
		self.blurEffectView.frame = CGRect(.zero, frame.size)
		self.addSubview(self.blurEffectView)

		self.imageView = UIImageView(frame: CGRect(0.0, 0.0, frame.height, frame.height))
		self.blurEffectView.contentView.addSubview(self.imageView)

		// Vibrancy over the play/pause button
		let vibrancyEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect))
		vibrancyEffectView.frame = CGRect(frame.right - frame.height, 0.0, 44.0, 44.0)
		self.blurEffectView.contentView.addSubview(vibrancyEffectView)

		// Play / pause button
		self.btnPlay = UIButton(type: .custom)
		self.btnPlay.frame = CGRect(6.0, 6.0, 32.0, 32.0)
		self.btnPlay.setImage(#imageLiteral(resourceName: "btn-play").withRenderingMode(.alwaysTemplate), for: .normal)
		self.btnPlay.addTarget(self, action: #selector(MiniPlayerView.changePlaybackAction(_:)), for: .touchUpInside)
		self.btnPlay.tag = PlayerStatus.stopped.rawValue
		self.btnPlay.isAccessibilityElement = true
		vibrancyEffectView.contentView.addSubview(self.btnPlay)

		// Dummy accessibility view
		self.accessibleView = UIView(frame: CGRect(self.imageView.right, 0.0, vibrancyEffectView.left - self.imageView.right, frame.height))
		self.accessibleView.backgroundColor = #colorLiteral(red: 1, green: 0.99997437, blue: 0.9999912977, alpha: 0)
		self.accessibleView.isAccessibilityElement = true
		self.blurEffectView.contentView.addSubview(self.accessibleView)

		// Title
		self.lblTitle = UILabel(frame: CGRect(self.imageView.right + 5.0, 2.0, ((vibrancyEffectView.left + 5.0) - (self.imageView.right + 5.0)), 18.0))
		self.lblTitle.textAlignment = .center
		self.lblTitle.font = UIFont(name: "GillSans-Bold", size: 14.0)
		self.lblTitle.textColor = isNightModeEnabled() ? #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		self.lblTitle.isAccessibilityElement = false
		self.blurEffectView.contentView.addSubview(self.lblTitle)

		// Artist
		self.lblArtist = UILabel(frame: CGRect(self.imageView.right + 5.0, self.lblTitle.bottom + 2.0, self.lblTitle.width, 16.0))
		self.lblArtist.textAlignment = .center
		self.lblArtist.font = UIFont(name: "GillSans", size: 12.0)
		self.lblArtist.textColor = isNightModeEnabled() ? #colorLiteral(red: 0.7540688515, green: 0.7540867925, blue: 0.7540771365, alpha: 1) : #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
		self.lblArtist.isAccessibilityElement = false
		self.blurEffectView.contentView.addSubview(self.lblArtist)

		// Progress
		self.progressView = UIView(frame: CGRect(0.0, 0.0, 0.0, 1.0))
		self.progressView.isAccessibilityElement = false
		self.addSubview(self.progressView)

		// Single tap to request full player view
		self.makeTappable()

		NotificationCenter.default.addObserver(self, selector: #selector(playingTrackNotification(_:)), name: .currentPlayingTrack, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(playerStatusChangedNotification(_:)), name: .playerStatusChanged, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(nightModeSettingDidChange(_:)), name: .nightModeSettingDidChange, object: nil)

		APP_DELEGATE().window?.addSubview(self)
	}

	required init?(coder aDecoder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Public
	func setInfoFromTrack(_ track: Track, ofAlbum album: Album)
	{
		lblTitle.text = track.name
		lblArtist.text = track.artist

		guard let url = album.localCoverURL else {return}
		if let image = UIImage(contentsOfFile: url.path)
		{
			let x = KawaiiColors(image: image)
			x.analyze()
			progressView.backgroundColor = x.dominantColor
			imageView.image = image.scaled(toSize: CGSize(imageView.width * UIScreen.main.scale, imageView.height * UIScreen.main.scale))
		}
		else
		{
			let sizeAsData = UserDefaults.standard.data(forKey: kNYXPrefCoverSize)!
			let cropSize = NSKeyedUnarchiver.unarchiveObject(with: sizeAsData) as! NSValue
			if album.path != nil
			{
				let op = CoverOperation(album: album, cropSize: cropSize.cgSizeValue)
				op.cplBlock = {(cover: UIImage, thumbnail: UIImage) in
					DispatchQueue.main.async {
						self.setInfoFromTrack(track, ofAlbum: album)
					}
				}
				APP_DELEGATE().operationQueue.addOperation(op)
			}
			else
			{
				MusicDataSource.shared.getPathForAlbum(album) {
					let op = CoverOperation(album: album, cropSize: cropSize.cgSizeValue)
					op.cplBlock = {(cover: UIImage, thumbnail: UIImage) in
						DispatchQueue.main.async {
							self.setInfoFromTrack(track, ofAlbum: album)
						}
					}
					APP_DELEGATE().operationQueue.addOperation(op)
				}
			}
		}
	}

	func show(_ animated: Bool = true)
	{
		NotificationCenter.default.post(name: .miniPlayerViewWillShow, object: nil)
		let w = UIApplication.shared.keyWindow!
		UIView.animate(withDuration: animated ? 0.35 : 0.0, delay: 0.0, options: UIViewAnimationOptions(), animations: {
			self.y = w.frame.height - self.height
		}, completion: { finished in
			self.visible = true
			NotificationCenter.default.post(name: .miniPlayerViewDidShow, object: nil)
		})
	}

	func hide(_ animated: Bool = true)
	{
		NotificationCenter.default.post(name: .miniPlayerViewWillHide, object: nil)
		let w = UIApplication.shared.keyWindow!
		UIView.animate(withDuration: animated ? 0.35 : 0.0, delay: 0.0, options: UIViewAnimationOptions(), animations: {
			self.y = w.frame.height + self.height
		}, completion: { finished in
			self.visible = false
			NotificationCenter.default.post(name: .miniPlayerViewDidHide, object: nil)
		})
	}

	// MARK: - Buttons actions
	func changePlaybackAction(_ sender: UIButton?)
	{
		if btnPlay.tag == PlayerStatus.playing.rawValue
		{
			btnPlay.setImage(#imageLiteral(resourceName: "btn-play").withRenderingMode(.alwaysTemplate), for: .normal)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_play")
		}
		else
		{
			btnPlay.setImage(#imageLiteral(resourceName: "btn-pause").withRenderingMode(.alwaysTemplate), for: .normal)
			btnPlay.accessibilityLabel = NYXLocalizedString("lbl_pause")
		}
		PlayerController.shared.togglePause()
	}

	// MARK: - PTappable
	func didTap()
	{
		NotificationCenter.default.post(name: .miniPlayerShouldExpand, object: nil)
	}

	// MARK: - Notifications
	func playingTrackNotification(_ aNotification: Notification)
	{
		if let infos = aNotification.userInfo
		{
			// Player not visible and should be
			if !visible && !stayHidden
			{
				show()
			}

			let track = infos[kPlayerTrackKey] as! Track
			let album = infos[kPlayerAlbumKey] as! Album
			let elapsed = infos[kPlayerElapsedKey] as! Int

			if track.name != lblTitle.text
			{
				setInfoFromTrack(track, ofAlbum: album)
			}

			let ratio = width / CGFloat(track.duration.seconds)
			UIView.animate(withDuration: 0.5) {
				self.progressView.width = ratio * CGFloat(elapsed)
			}
			accessibleView.accessibilityLabel = "\(track.name) \(NYXLocalizedString("lbl_by")) \(track.artist)\n\((100 * elapsed) / Int(track.duration.seconds))% \(NYXLocalizedString("lbl_played"))"
		}
	}

	func playerStatusChangedNotification(_ aNotification: Notification)
	{
		if let infos = aNotification.userInfo
		{
			let state = infos[kPlayerStatusKey] as! Int
			if state == PlayerStatus.playing.rawValue
			{
				btnPlay.setImage(#imageLiteral(resourceName: "btn-pause").withRenderingMode(.alwaysTemplate), for: .normal)
				btnPlay.accessibilityLabel = NYXLocalizedString("lbl_pause")
			}
			else
			{
				btnPlay.setImage(#imageLiteral(resourceName: "btn-play").withRenderingMode(.alwaysTemplate), for: .normal)
				btnPlay.accessibilityLabel = NYXLocalizedString("lbl_play")
			}
			btnPlay.tag = state
		}
	}

	func nightModeSettingDidChange(_ aNotification: Notification?)
	{
		if isNightModeEnabled()
		{
			blurEffectView.effect = UIBlurEffect(style: .dark)
			lblTitle.textColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
			lblArtist.textColor = #colorLiteral(red: 0.7540688515, green: 0.7540867925, blue: 0.7540771365, alpha: 1)
		}
		else
		{
			blurEffectView.effect = UIBlurEffect(style: .light)
			lblTitle.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
			lblArtist.textColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
		}
	}
}
