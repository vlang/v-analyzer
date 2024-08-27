module lsp

pub struct RenameOptions {
pub:
	prepare_provider bool @[json: prepareProvider]
}

// method: ‘textDocument/rename’
// response: WorkspaceEdit | none
pub struct RenameParams {
pub:
	text_document TextDocumentIdentifier @[json: textDocument]
	position      Position
	new_name      string @[json: newName]
}

pub struct RenameRegistrationOptions {
pub:
	document_selector []DocumentFilter @[json: documentSelector]
	prepare_provider  bool             @[json: prepareProvider]
}

// method: ‘textDocument/prepareRename’
// response: Range | { range: Range, placeholder: string } | none
// request: TextDocumentPositionParams

pub struct PrepareRenameParams {
pub:
	text_document TextDocumentIdentifier @[json: textDocument]
	position      Position
}

pub struct PrepareRenameResult {
pub:
	range       Range
	placeholder string
}
