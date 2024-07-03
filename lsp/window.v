// MIT License
//
// Copyright (c) 2023-2024 V Open Source Community Association (VOSCA) vosca.dev
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
module lsp

// method: ‘window/showMessage’
// notification
pub struct ShowMessageParams {
	@type MessageType
	// @type int
	message string
}

@[json_as_number]
pub enum MessageType {
	error   = 1
	warning = 2
	info    = 3
	log     = 4
}

// method: ‘window/showMessageRequest’
// response: MessageActionItem | none / null
pub struct ShowMessageRequestParams {
	@type   MessageType
	message string
	actions []MessageActionItem
}

pub struct MessageActionItem {
	title string
}

// method: ‘window/logMessage’
// notification
pub struct LogMessageParams {
	@type   MessageType
	message string
}

// method: ‘telemetry/event
// notification
// any
