// DownloadCoverOperation.swift
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


final class DownloadCoverOperation : NSOperation
{
	// MARK: - Private properties
	// isFinished override
	private var junk: Bool = false
	override var finished: Bool {
		get {
			return junk
		}
		set (newAnswer) {
			willChangeValueForKey("isFinished")
			junk = newAnswer
			didChangeValueForKey("isFinished")
		}
	}

	// Downloaded data
	private let incomingData = NSMutableData()
	// Task
	private var sessionTask: NSURLSessionTask?
	// Session configuration
	private var localURLSessionConfiguration: NSURLSessionConfiguration {
		let cfg = NSURLSessionConfiguration.defaultSessionConfiguration()
		cfg.HTTPShouldUsePipelining = true
		return cfg
	}
	// Session
	private var localURLSession: NSURLSession {
		return NSURLSession(configuration:self.localURLSessionConfiguration, delegate:self, delegateQueue:nil)
	}

	// MARK : Public properties
	// Album
	let album: Album
	// Size of the thumbnail to create
	let cropSize: CGSize
	// Custom completion block
	var cplBlock: ((UIImage, UIImage) -> Void)? = nil

	// MARK: - Initializers
	init(album: Album, cropSize: CGSize)
	{
		self.album = album
		self.cropSize = cropSize
	}

	// MARK: - Override
	override func start()
	{
		// Operation is cancelled, abort
		if self.cancelled
		{
			Logger.dlog("[+] Cancelled !")
			self.finished = true
			return
		}

		// No path for album, abort
		guard let path = self.album.path else
		{
			Logger.alog("[!] No album art path defined.")
			self.finished = true
			return
		}

		// No mpd server configured, abort
		guard let serverAsData = NSUserDefaults.standardUserDefaults().dataForKey(kNYXPrefMPDServer) else
		{
			Logger.alog("[!] No MPD server configured.")
			self.finished = true
			return
		}
		guard let server = NSKeyedUnarchiver.unarchiveObjectWithData(serverAsData) as! MPDServer? else
		{
			Logger.alog("[!] No MPD server configured.")
			self.finished = true
			return
		}
		// No cover stuff configured, abort
		if server.coverURL.length <= 0 || server.coverName.length <= 0
		{
			Logger.alog("[!] No web server configured, can't download covers.")
			self.finished = true
			return
		}

		let allowedCharacters = NSCharacterSet(charactersInString:"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_/.")
		var coverURLAsString = path + "/" + server.coverName
		coverURLAsString = coverURLAsString.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)!
		let urlAsString = server.coverURL + coverURLAsString

		let request = NSMutableURLRequest(URL:NSURL(string:urlAsString)!)
		request.addValue("image/*", forHTTPHeaderField:"Accept")

		self.sessionTask = self.localURLSession.dataTaskWithRequest(request)
		self.sessionTask!.resume()
	}

	// MARK: - Private
	private func processData()
	{
		guard let cover = UIImage(data:self.incomingData) else
		{
			self.album.hasCover = false
			return
		}
		guard let thumbnail = cover.imageCroppedToFitSize(self.cropSize) else
		{
			self.album.hasCover = false
			return
		}
		guard let saveURL = self.album.localCoverURL else
		{
			self.album.hasCover = false
			return
		}
		UIImageJPEGRepresentation(thumbnail, 0.7)?.writeToURL(saveURL, atomically:true)
		self.album.hasCover = true

		if let cpl = self.cplBlock
		{
			cpl(cover, thumbnail)
		}
	}
}

// MARK: - NSURLSessionDelegate
extension DownloadCoverOperation : NSURLSessionDelegate
{
	func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void)
	{
		if self.cancelled
		{
			Logger.dlog("[+] Cancelled !")
			self.sessionTask?.cancel()
			self.finished = true
			return
		}

		completionHandler(.Allow)
	}

	func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData)
	{
		if self.cancelled
		{
			Logger.dlog("[+] Cancelled !")
			self.sessionTask?.cancel()
			self.finished = true
			return
		}
		self.incomingData.appendData(data)
	}

	func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?)
	{
		if self.cancelled
		{
			Logger.dlog("[+] Cancelled !")
			self.sessionTask?.cancel()
			self.finished = true
			return
		}

		if error != nil
		{
			Logger.alog("[!] Failed to receive response: \(error?.localizedDescription)")
			self.finished = true
			return
		}
		self.processData()
		self.finished = true
	}
}
