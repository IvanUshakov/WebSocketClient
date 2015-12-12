// WebSocketsServer.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Core
import HTTP

internal extension Request {
	internal var isWebSocket: Bool {
		if let connection = getHeader("connection"), upgrade = getHeader("upgrade"), version = getHeader("sec-websocket-version"), _ = getHeader("sec-websocket-key")
			where connection.lowercaseString == "upgrade" && upgrade.lowercaseString == "websocket" && version == "13" {
				return true
		} else {
			return false
		}
	}
}

public class WebSocketsServer {

	private var sockets: [WebSocket] = []

	public init() {

	}

	public func handleContext(context: Context, websocketHandler: WebSocket -> Void) -> Bool {
		guard context.request.isWebSocket else { return false }
		guard let wsKey = context.request.getHeader("sec-websocket-key") else { return false }

		let acceptKey = Base64.encodeString(bytes: SHA1.bytes(wsKey + WebSocket.KeyGuid))
		let headers = ["Connection": "Upgrade", "Upgrade": "websocket", "Sec-WebSocket-Accept": acceptKey]
		let response = Response(status: .SwitchingProtocols, headers: headers)
		context.upgrade(response) { streamResult in
			do {
				let stream = try streamResult()
				let socket = WebSocket(context: context, stream: stream)
				self.sockets.append(socket)
				websocketHandler(socket)
			} catch {
				print("upgrade error: \(error)")
			}
		}

		return true
	}

}
