// InteractableImageView.swift
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


final class InteractableImageView : UIImageView, PTappable, PLeftSwippable, PRightSwippable, PUpSwippable, PDownSwippable
{
	// MARK: - Public properties
	// Delegate
	weak var delegate: InteractableImageViewDelegate? = nil

	// MARK: - PTappable
	func didTap()
	{
		delegate?.didTap()
	}

	// MARK: - PLeftSwippable
	func didSwipeLeft()
	{
		delegate?.didSwipeLeft()
	}

	// MARK: - PRightSwippable
	func didSwipeRight()
	{
		delegate?.didSwipeRight()
	}

	// MARK: - PUpSwippable
	func didSwipeUp()
	{
		delegate?.didSwipeUp()
	}

	// MARK: - PDownSwippable
	func didSwipeDown()
	{
		delegate?.didSwipeDown()
	}
}

protocol InteractableImageViewDelegate : class
{
	func didTap()
	func didSwipeLeft()
	func didSwipeRight()
	func didSwipeUp()
	func didSwipeDown()
}

extension InteractableImageViewDelegate
{
	func didTap()
	{
		return
	}

	func didSwipeLeft()
	{
		return
	}

	func didSwipeRight()
	{
		return
	}

	func didSwipeUp()
	{
		return
	}

	func didSwipeDown()
	{
		return
	}
}
