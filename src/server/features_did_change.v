module server

import lsp
import analyzer
import time
import loglib

pub fn (mut ls LanguageServer) did_change(params lsp.DidChangeTextDocumentParams) {
	uri := params.text_document.uri.normalize()
	mut file := ls.opened_files[uri] or {
		loglib.with_fields({
			'uri':    uri.str()
			'params': params.str()
			'caller': @METHOD
		}).error('File not opened')
		return
	}
	new_content := params.content_changes[0].text
	file.psi_file.reparse(new_content)
	ls.opened_files[uri] = analyzer.OpenedFile{
		uri: uri
		version: file.version++
		psi_file: file.psi_file
	}

	ls.indexing_mng.indexer.mark_as_dirty(uri.path(), new_content) or {
		loglib.with_fields({
			'uri':    uri.str()
			'params': params.str()
			'caller': @METHOD
			'err':    err.str()
		}).error('Error marking document as dirty')
	}

	watch := time.new_stopwatch(auto_start: true)
	ls.indexing_mng.update_stub_indexes([file.psi_file])

	type_cache.clear()
	resolve_cache.clear()
	enum_fields_cache = map[string]int{}

	loglib.with_fields({
		'caller':   @METHOD
		'duration': watch.elapsed().str()
	}).info('Updated stub indexes')

	loglib.with_fields({
		'uri': uri.str()
	}).info('Reparsed file')
}
