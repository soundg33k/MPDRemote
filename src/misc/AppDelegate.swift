// AppDelegate.swift
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


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
	// MARK: - Properties
	// Main window
	var window: UIWindow?
	// Albums list VC
	private(set) var homeVC: UIViewController! = nil
	// Server configuration VC
	private(set) lazy var serverVC: UIViewController = {
		let sb = UIStoryboard(name: "main", bundle: nil)
		let vc = sb.instantiateViewController(withIdentifier: "ServerNVC")
		return vc
	}()
	// Player VC
	private(set) lazy var playerVC: PlayerVC = {
		let sb = UIStoryboard(name: "main", bundle: nil)
		let vc = sb.instantiateViewController(withIdentifier: "PlayerVC")
		return vc as! PlayerVC
	}()
	// Stats VC
	private(set) lazy var statsVC: UIViewController = {
		let sb = UIStoryboard(name: "main", bundle: nil)
		let vc = sb.instantiateViewController(withIdentifier: "StatsNVC")
		return vc
	}()
	// Settings VC
	private(set) lazy var settingsVC: UIViewController = {
		let sb = UIStoryboard(name: "main", bundle: nil)
		let vc = sb.instantiateViewController(withIdentifier: "SettingsNVC")
		return vc
	}()

	// MARK: - UIApplicationDelegate
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool
	{
		// Register default preferences
		_registerDefaultPreferences()

		// URL cache
		URLCache.shared = URLCache(memoryCapacity: 4.MB(), diskCapacity: 32.MB(), diskPath: nil)

		homeVC = window?.rootViewController

		return true
	}

	// MARK: - Private
	private func _registerDefaultPreferences()
	{
		let coversDirectoryPath = "covers"
		let columns = CGFloat(3)
		let span = CGFloat(10)
		let width = ceil((UIScreen.main.bounds.width / columns) - (2 * span))
		let defaults: [String: Any] =
		[
			kNYXPrefCoversDirectory : coversDirectoryPath,
			kNYXPrefCoversSize : NSKeyedArchiver.archivedData(withRootObject: NSValue(cgSize: CGSize(width, width))),
			kNYXPrefFuzzySearch : false,
			kNYXPrefMPDShuffle : false,
			kNYXPrefMPDRepeat : false,
			kNYXPrefDisplayType : DisplayType.albums.rawValue,
			kNYXPrefShakeToPlayRandomAlbum : false,
			kNYXPrefCollectionViewLayoutTable : false,
			kNYXPrefEnableLogging : false,
			kNYXPrefLastKnownVersion : Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? ""
		]

		let cachesDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last!

		do
		{
			try FileManager.default.createDirectory(at: cachesDirectoryURL.appendingPathComponent(coversDirectoryPath), withIntermediateDirectories: true, attributes: nil)
		}
		catch let error
		{
			Logger.shared.log(error: error)
			fatalError("Failed to create covers directory")
		}

		UserDefaults.standard.register(defaults: defaults)
		UserDefaults.standard.synchronize()
	}
}
