// Swippable.swift
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


public protocol PLeftSwippable
{
	func makeLeftSwippable()
	func didSwipeLeft()
}

public extension PLeftSwippable where Self:UIView
{
	func makeLeftSwippable()
	{
		let gestureRecognizer = UISwipeGestureRecognizer { [unowned self] (recognizer) -> Void in
			let swipe = recognizer as! UISwipeGestureRecognizer

			if swipe.state == .Ended
			{
				self.didSwipeLeft()
			}
		}
		gestureRecognizer.direction = .Left
		self.addGestureRecognizer(gestureRecognizer);
	}

	func didSwipeLeft()
	{
		return
	}
}

public protocol PRightSwippable
{
	func makeRightSwippable()
	func didSwipeRight()
}

public extension PRightSwippable where Self:UIView
{
	func makeRightSwippable()
	{
		let gestureRecognizer = UISwipeGestureRecognizer { [unowned self] (recognizer) -> Void in
			let swipe = recognizer as! UISwipeGestureRecognizer

			if swipe.state == .Ended
			{
				self.didSwipeRight()
			}
		}
		gestureRecognizer.direction = .Right
		self.addGestureRecognizer(gestureRecognizer);
	}

	func didSwipeRight()
	{
		return
	}
}

public protocol PUpSwippable
{
	func makeUpSwippable()
	func didSwipeUp()
}

public extension PUpSwippable where Self:UIView
{
	func makeUpSwippable()
	{
		let gestureRecognizer = UISwipeGestureRecognizer { [unowned self] (recognizer) -> Void in
			let swipe = recognizer as! UISwipeGestureRecognizer

			if swipe.state == .Ended
			{
				self.didSwipeUp()
			}
		}
		gestureRecognizer.direction = .Up
		addGestureRecognizer(gestureRecognizer);
	}

	func didSwipeUp()
	{
		return
	}
}

public protocol PDownSwippable
{
	func makeDownSwippable()
	func didSwipeDown()
}

public extension PDownSwippable where Self:UIView
{
	func makeDownSwippable()
	{
		let gestureRecognizer = UISwipeGestureRecognizer { [unowned self] (recognizer) -> Void in
			let swipe = recognizer as! UISwipeGestureRecognizer

			if swipe.state == .Ended
			{
				self.didSwipeDown()
			}
		}
		gestureRecognizer.direction = .Down
		addGestureRecognizer(gestureRecognizer);
	}

	func didSwipeDown()
	{
		return
	}
}
