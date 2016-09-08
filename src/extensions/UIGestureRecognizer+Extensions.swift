// UIGestureRecognizer+Extensions.swift
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
import ObjectiveC


private final class Wrapper<T>
{
	let value: T
	init(_ x: T)
	{
		self.value = x
	}
}

class Associator
{
	static private func wrap<T>(_ x: T) -> Wrapper<T>
	{
		return Wrapper(x)
	}

	static func setAssociatedObject<T>(_ object: AnyObject, value: T, associativeKey: UnsafePointer<Void>, policy: objc_AssociationPolicy)
	{
		if let v: AnyObject = value as? AnyObject
		{
			objc_setAssociatedObject(object, associativeKey, v, policy)
		}
		else
		{
			objc_setAssociatedObject(object, associativeKey, wrap(value), policy)
		}
	}

	static func getAssociatedObject<T>(_ object: AnyObject, associativeKey: UnsafePointer<Void>) -> T?
	{
		if let v = objc_getAssociatedObject(object, associativeKey) as? T
		{
			return v
		}
		else if let v = objc_getAssociatedObject(object, associativeKey) as? Wrapper<T>
		{
			return v.value
		}
		else
		{
			return nil
		}
	}
}

private class MultiDelegate : NSObject, UIGestureRecognizerDelegate
{
	@objc func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
	{
		return true
	}
}

extension UIGestureRecognizer
{
	struct PropertyKeys
	{
		static var blockKey = "key-block"
		static var multiDelegateKey = "key-delegate"
	}

	private var block:((recognizer:UIGestureRecognizer) -> Void)
	{
		get
		{
			return Associator.getAssociatedObject(self, associativeKey:&PropertyKeys.blockKey)!
		}
		set
		{
			Associator.setAssociatedObject(self, value:newValue, associativeKey:&PropertyKeys.blockKey, policy:objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
		}
	}

	private var multiDelegate:MultiDelegate
	{
		get
		{
			return Associator.getAssociatedObject(self, associativeKey:&PropertyKeys.multiDelegateKey)!
		}
		set
		{
			Associator.setAssociatedObject(self, value:newValue, associativeKey:&PropertyKeys.multiDelegateKey, policy:objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
		}
	}

	convenience init(block:(recognizer:UIGestureRecognizer) -> Void)
	{
		self.init()
		self.block = block
		self.multiDelegate = MultiDelegate()
		self.delegate = self.multiDelegate
		self.addTarget(self, action:#selector(UIGestureRecognizer.didInteractWithGestureRecognizer(_:)))
	}

	@objc func didInteractWithGestureRecognizer(_ sender:UIGestureRecognizer)
	{
		block(recognizer:sender)
	}
}
