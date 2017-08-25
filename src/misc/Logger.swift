// Logger.swift
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


enum LogType : String
{
	case debug = "💜"
	case success = "💚"
	case warning = "💛"
	case error = "❤️"
}

fileprivate struct Log : CustomStringConvertible
{
	let type: LogType
	let dateString: String
	let message: String
	let file: String
	let function: String
	let line: Int

	init(type t: LogType, date d: String, message m: String)
	{
		type = t
		message = m
		dateString = d
		file = #file
		function = #function
		line = #line
	}

	var description: String
	{
		return "[\(type)] [\(dateString)] [\(file)] [\(function)] [\(line)]\n↳ \(message)"
	}
}

final class Logger
{
	static let shared = Logger()

	private let _df: DateFormatter

	private var logs: [Log]
	private let logsCount = 4096

	init()
	{
		_df = DateFormatter()
		_df.dateFormat = "dd/MM/yy HH:mm:ss"

		logs = [Log]()
	}

	public func log(type: LogType, message: String, logToConsole: Bool = false)
	{
		let log = Log(type: type, date: _df.string(from: Date()), message: message)

		handleLog(log)

#if NYX_DEBUG
		print(log)
#else
		if logToConsole
		{
			print(log)
		}
#endif
	}

	public func export() -> Data?
	{
		let str = logs.reduce("") {"\($1)\n\n"}
		return str.data(using: .utf8)
	}

	private func handleLog(_ log: Log)
	{
		logs.append(log)

		if logs.count > logsCount
		{
			logs.remove(at: 0)
		}
	}
}
