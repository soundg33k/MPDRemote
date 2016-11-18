// CoverOperation.swift
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
import Foundation


final class CoverOperation : Operation
{
	// MARK: - Private properties
	// isFinished override
	private var junk: Bool = false
	override var isFinished: Bool {
		get {
			return junk
		}
		set (newAnswer) {
			willChangeValue(forKey: "isFinished")
			junk = newAnswer
			didChangeValue(forKey: "isFinished")
		}
	}

	// Downloaded data
	let incomingData = NSMutableData()
	// Task
	var sessionTask: URLSessionTask?
	// Session configuration
	private var localURLSessionConfiguration: URLSessionConfiguration {
		let cfg = URLSessionConfiguration.default
		cfg.httpShouldUsePipelining = true
		return cfg
	}
	// Session
	private var localURLSession: Foundation.URLSession {
		return Foundation.URLSession(configuration: localURLSessionConfiguration, delegate: self, delegateQueue: nil)
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
		if isCancelled
		{
			Logger.dlog("[+] Cancelled !")
			isFinished = true
			return
		}

		// No path for album, abort
		guard let path = album.path else
		{
			Logger.dlog("[!] No album path defined.")
			isFinished = true
			return
		}

		// No mpd server configured, abort
		guard let serverAsData = UserDefaults.standard.data(forKey: kNYXPrefWEBServer) else
		{
			Logger.dlog("[!] No WEB server configured.")
			generateCover()
			isFinished = true
			return
		}
		guard let server = NSKeyedUnarchiver.unarchiveObject(with: serverAsData) as! CoverWebServer? else
		{
			Logger.dlog("[!] No WEB server configured.")
			generateCover()
			isFinished = true
			return
		}
		// No cover stuff configured, abort
		if server.hostname.length <= 0 || server.coverName.length <= 0
		{
			Logger.dlog("[!] No web server configured, can't download covers.")
			generateCover()
			isFinished = true
			return
		}

		let allowedCharacters = CharacterSet(charactersIn:"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_/.")
		var coverURLAsString = path + "/" + server.coverName
		coverURLAsString = coverURLAsString.addingPercentEncoding(withAllowedCharacters: allowedCharacters)!
		let urlAsString = server.hostname + ":\(server.port)" + coverURLAsString

		var request = URLRequest(url: URL(string: urlAsString)!)
		request.addValue("image/*", forHTTPHeaderField: "Accept")

		sessionTask = localURLSession.dataTask(with: request)
		sessionTask!.resume()
	}

	// MARK: - Private
	func processData()
	{
		guard let cover = UIImage(data: incomingData as Data) else
		{
			return
		}
		guard let thumbnail = cover.smartCropped(toSize: cropSize) else
		{
			return
		}
		guard let saveURL = album.localCoverURL else
		{
			return
		}
		try! UIImageJPEGRepresentation(thumbnail, 0.7)?.write(to: saveURL, options: [.atomicWrite])

		if let cpl = cplBlock
		{
			cpl(cover, thumbnail)
		}
	}

	private func generateCover()
	{
		let width = UIScreen.main.bounds.width - 64.0
		guard let cover = generateCoverForAlbum(album, size: CGSize(width, width)) else {return}
		guard let thumbnail = cover.smartCropped(toSize: cropSize) else {return}
		guard let saveURL = album.localCoverURL else
		{
			return
		}
		try! UIImageJPEGRepresentation(thumbnail, 0.7)?.write(to: saveURL, options: [.atomicWrite])
		if let cpl = cplBlock
		{
			cpl(cover, thumbnail)
		}
	}
}

// MARK: - NSURLSessionDelegate
extension CoverOperation : URLSessionDelegate
{
	func URLSession(_ session: Foundation.URLSession, dataTask: URLSessionDataTask, didReceiveResponse response: URLResponse, completionHandler: (Foundation.URLSession.ResponseDisposition) -> Void)
	{
		if isCancelled
		{
			Logger.dlog("[+] Cancelled !")
			sessionTask?.cancel()
			isFinished = true
			return
		}

		completionHandler(.allow)
	}

	func URLSession(_ session: Foundation.URLSession, dataTask: URLSessionDataTask, didReceiveData data: Data)
	{
		if isCancelled
		{
			Logger.dlog("[+] Cancelled !")
			sessionTask?.cancel()
			isFinished = true
			return
		}
		incomingData.append(data)
	}

	func URLSession(_ session: Foundation.URLSession, task: URLSessionTask, didCompleteWithError error: NSError?)
	{
		if isCancelled
		{
			Logger.dlog("[+] Cancelled !")
			sessionTask?.cancel()
			isFinished = true
			return
		}

		if error != nil
		{
			Logger.alog("[!] Failed to receive response: \(error?.localizedDescription)")
			isFinished = true
			return
		}
		processData()
		isFinished = true
	}

	private func urlSession(_ session: Foundation.URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: (Foundation.URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
	{
		completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
	}
}
