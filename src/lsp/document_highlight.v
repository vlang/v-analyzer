module lsp

// method: ‘textDocument/documentHighlight’
// response: []DocumentHighlight | none
// request: TextDocumentPositionParams
pub struct DocumentHighlight {
	range Range
	kind  DocumentHighlightKind
}

@[json_as_number]
pub enum DocumentHighlightKind {
	text  = 1
	read  = 2
	write = 3
}
