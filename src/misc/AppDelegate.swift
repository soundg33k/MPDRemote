// AppDelegate.swift
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


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
	// MARK: - Properties
	// Main window
	var window: UIWindow?
	// Operation queue
	private(set) var operationQueue: NSOperationQueue! = nil
	// Albums list VC
	private(set) var homeVC: UIViewController! = nil
	// Server configuration VC
	private(set) lazy var serverVC: UIViewController = {
		return NYXNavigationController(rootViewController:ServerVC())
	}()
	// Player VC
	private(set) lazy var playerVC: PlayerVC = {
		return PlayerVC()
	}()

	// MARK: - UIApplicationDelegate
	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
	{
		// Register default preferences
		self._registerDefaultPreferences()

		// URL cache
		NSURLCache.setSharedURLCache(NSURLCache(memoryCapacity:(4 * 1024 * 1024), diskCapacity:(32 * 1024 * 1024), diskPath:nil))

		// Global operation queue
		self.operationQueue = NSOperationQueue()
		self.operationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount

		self.homeVC = UIDevice.isPhone() ? NYXNavigationController(rootViewController:RootVC()) : UIViewController()
		self.window = UIWindow()
		self.window?.rootViewController = self.homeVC
		self.window?.makeKeyAndVisible()

		NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(miniPlayShouldExpandNotification(_:)), name:kNYXNotificationMiniPlayerShouldExpand, object:nil)

		return true
	}

	// MARK: - Private
	private func _registerDefaultPreferences()
	{
		let coversDirectoryPath = "covers"
		let columns = CGFloat(3)
		let span = CGFloat(10)
		let width = ceil((UIScreen.mainScreen().bounds.width / columns) - (2 * span))
		let defaults: [String: AnyObject] =
		[
			kNYXPrefDirectoryCovers : coversDirectoryPath,
			kNYXPrefCoverSize : NSKeyedArchiver.archivedDataWithRootObject(NSValue(CGSize:CGSize(width, width))),
			kNYXPrefRandom : false,
			kNYXPrefRepeat : false,
			kNYXPrefVolume : 100,
			kNYXPrefDisplayType : DisplayType.Albums.rawValue,
		]

		let fileManager = NSFileManager()
		let cachesDirectoryURL = fileManager.URLsForDirectory(.CachesDirectory, inDomains:.UserDomainMask).last!

		try! fileManager.createDirectoryAtURL(cachesDirectoryURL.URLByAppendingPathComponent(coversDirectoryPath), withIntermediateDirectories:true, attributes:nil)

		NSUserDefaults.standardUserDefaults().registerDefaults(defaults)
		NSUserDefaults.standardUserDefaults().synchronize()
	}

	// MARK: - Notifications
	func miniPlayShouldExpandNotification(aNotification: NSNotification)
	{
		self.window?.rootViewController?.presentViewController(self.playerVC, animated:true, completion:nil)
		MiniPlayerView.shared.stayHidden = true
		MiniPlayerView.shared.hide()
	}
}
