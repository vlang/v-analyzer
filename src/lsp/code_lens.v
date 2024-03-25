module lsp

pub struct CodeLensOptions {
pub mut:
	resolve_provider   bool @[json: 'resolveProvider'; omitempty]
	work_done_progress bool @[json: 'workDoneProgress'; omitempty]
}

// method: ‘textDocument/codeLens’
// response: []CodeLens | none
pub struct CodeLensParams {
	WorkDoneProgressParams
pub:
	text_document TextDocumentIdentifier @[json: textDocument]
}

pub struct CodeLens {
pub:
	// The range in which this code lens is valid. Should only span a single
	// line.
	range Range
	// The command this code lens represents.
	command Command
	// A data entry field that is preserved on a code lens item between
	// a code lens and a code lens resolve request.
	data string @[raw]
}

pub struct CodeLensRegistrationOptions {
	document_selector []DocumentFilter @[json: documentSelector]
	resolve_provider  bool             @[json: resolveProvider]
}

// method: ‘codeLens/resolve’
// response: CodeLens
// request: CodeLens
