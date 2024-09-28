module server

import lsp
import os
import analyzer
import analyzer.psi
import analyzer.parser




fn test_large_file() {


	test_file := os.norm_path(@VMODROOT + '/src/server/general.v')
	// test_file := os.norm_path(@VEXEROOT + '/vlib/os/process_windows.c.v')
	// test_file := 'file:///c%3A/Users/phcre/Documents/v/imageeditor/testing/proc.v'
	dump(test_file)

	src := os.read_file(test_file) or { panic('Cannot read file') }
	// dump(src)

	uri := lsp.document_uri_from_path(test_file)
	res := parser.parse_code(src)
	psi_file := psi.new_psi_file(uri.path(), res.tree, res.source_text)


	mut ls := LanguageServer.new(analyzer.IndexingManager.new())
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
	dump(text_edit_result)
	assert text_edit_result.len == 1

}
