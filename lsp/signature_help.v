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

pub struct SignatureHelpOptions {
	trigger_characters   []string @[json: triggerCharacters]
	retrigger_characters []string @[json: retriggerCharacters]
}

@[json_as_number]
pub enum SignatureHelpTriggerKind {
	invoked           = 1
	trigger_character = 2
	content_change    = 3
}

// method: ‘textDocument/signatureHelp’
// response: SignatureHelp | none
pub struct SignatureHelpParams {
pub:
	// TODO: utilize struct embedding feature
	// for all structs that use TextDocumentPositionParams
	// embed: TextDocumentPositionParams
	text_document TextDocumentIdentifier @[json: textDocument]
	position      Position
	context       SignatureHelpContext
}

pub struct SignatureHelpContext {
pub:
	trigger_kind          SignatureHelpTriggerKind @[json: triggerKind]
	trigger_character     string                   @[json: triggerCharacter]
	is_retrigger          bool                     @[json: isRetrigger]
	active_signature_help SignatureHelp            @[json: activeSignatureHelp]
}

pub struct SignatureHelp {
pub:
	signatures []SignatureInformation
pub mut:
	active_parameter int @[json: activeParameter]
}

pub struct SignatureInformation {
pub mut:
	label string
	// documentation MarkupContent
	parameters []ParameterInformation
}

pub struct ParameterInformation {
	label string
}

pub struct SignatureHelpRegistrationOptions {
	document_selector  []DocumentFilter @[json: documentSelector]
	trigger_characters []string         @[json: triggerCharacters]
}
