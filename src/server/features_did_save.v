module server

import lsp

pub fn (mut ls LanguageServer) did_save(params lsp.DidSaveTextDocumentParams) {
	uri := params.text_document.uri.normalize()
	ls.run_diagnostics_in_bg(uri)
}
