// Common.swift
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

/* Ugly AppDelegate shortcut */
func APP_DELEGATE() -> AppDelegate {return UIApplication.shared.delegate as! AppDelegate}

/* Preferences keys */
public let kNYXPrefDirectoryCovers = "kNYXPrefDirectoryCovers"
public let kNYXPrefMPDServer = "kNYXPrefMPDServer"
public let kNYXPrefWEBServer = "kNYXPrefWEBServer"
public let kNYXPrefCoverSize = "kNYXPrefCoverSize"
public let kNYXPrefRandom = "kNYXPrefRandom"
public let kNYXPrefRepeat = "kNYXPrefRepeat"
public let kNYXPrefVolume = "kNYXPrefVolume"
public let kNYXPrefDisplayType = "kNYXPrefDisplayType"

/* Notifications names */
public let kNYXNotificationCurrentPlayingTrack = "kNYXNotificationCurrentPlayingTrack"
public let kNYXNotificationPlayingTrackChanged = "kNYXNotificationPlayingTrackChanged"
public let kNYXNotificationPlayerStatusChanged = "kNYXNotificationPlayerStatusChanged"
public let kNYXNotificationMiniPlayerViewWillShow = "kNYXNotificationMiniPlayerViewWillShow"
public let kNYXNotificationMiniPlayerViewDidShow = "kNYXNotificationMiniPlayerViewDidShow"
public let kNYXNotificationMiniPlayerViewWillHide = "kNYXNotificationMiniPlayerViewWillHide"
public let kNYXNotificationMiniPlayerViewDidHide = "kNYXNotificationMiniPlayerViewDidHide"
public let kNYXNotificationMiniPlayerShouldExpand = "kNYXNotificationMiniPlayerShouldExpand"

/* App color */
public let kNYXAppColor = Int(0x660000)

/* RootVC display type */
enum DisplayType : Int
{
	case albums
	case artists
	case genres
}
