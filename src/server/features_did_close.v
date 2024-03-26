module server

import lsp
import loglib

pub fn (mut ls LanguageServer) did_close(params lsp.DidCloseTextDocumentParams) {
	uri := params.text_document.uri.normalize()
	// if file := ls.opened_files[uri] {
	// 	unsafe { file.psi_file.tree.free() }
	// }

	ls.opened_files.delete(uri)

	loglib.with_fields({
		'uri':              uri.str()
		'opened_files len': ls.opened_files.len.str()
	}).info('closed file')
}
