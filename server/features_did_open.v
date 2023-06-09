module server

import lsp
import analyzer
import analyzer.psi
import analyzer.parser
import loglib

pub fn (mut ls LanguageServer) did_open(params lsp.DidOpenTextDocumentParams, mut wr ResponseWriter) {
	src := params.text_document.text
	uri := params.text_document.uri.normalize()

	res := parser.parse_code(src)
	psi_file := psi.new_psi_file(uri.path(), res.tree, res.source_text)

	ls.opened_files[uri] = analyzer.OpenedFile{
		uri: uri
		version: 0
		psi_file: psi_file
	}

	// Useful for debugging
	//
	// mut visitor := psi.PrinterVisitor{}
	// psi_file.root().accept_mut(mut visitor)
	// visitor.print()
	//
	// tree := index.build_stub_tree(psi_file)
	// tree.print()

	loglib.with_fields({
		'uri':              uri.str()
		'opened_files len': ls.opened_files.len.str()
	}).info('Opened file')
}