// OperationManager.swift
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


import Foundation


final class OperationManager
{
	// Singletion instance
	static let shared = OperationManager()
	// Global operation queue
	private var operationQueue: OperationQueue! = nil
	//
	//private var _bla = [String]()

	// MARK: - Initializers
	init()
	{
		operationQueue = OperationQueue()
		operationQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
	}

	func addOperation(_ operation: Operation)
	{
		/*if operation is CoverOperation
		{
			let op = operation as! CoverOperation
			if _bla.contains(op.album.uniqueIdentifier)
			{
				return
			}
			else
			{
				_bla.append(op.album.uniqueIdentifier)
				op.completionBlock = { [weak self] in
					self?._bla.removeObject(object: op.album.uniqueIdentifier)
				}
			}
		}*/
		operationQueue.addOperation(operation)
	}

	func cancelAllOperations()
	{
		//_bla.removeAll()
		operationQueue.cancelAllOperations()
	}
}
