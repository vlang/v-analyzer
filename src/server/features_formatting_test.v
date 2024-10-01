module server

import lsp
import os
import analyzer
import analyzer.psi
import analyzer.parser

fn test_large_file() {
	test_file := os.real_path(@VMODROOT + '/src/server/general.v')

	src := os.read_file(test_file) or { panic('Cannot read file') }

	mut ls := LanguageServer.new(analyzer.IndexingManager.new())
	ls.setup_toolchain()
	ls.setup_vpaths()

	uri := lsp.document_uri_from_path(test_file)
	res := parser.parse_code(src)
	psi_file := psi.new_psi_file(uri.path(), res.tree, res.source_text)
	ls.opened_files[uri] = analyzer.OpenedFile{
		uri:      uri
		version:  0
		psi_file: psi_file
	}

	params := lsp.DocumentFormattingParams{
		text_document: lsp.TextDocumentIdentifier{
			uri: uri
		}
	}

	text_edit_result := ls.formatting(params) or { panic('Cannot format file') }
	assert text_edit_result.len == 1
}
