module server

import lsp
import loglib
import server.tform
import analyzer.psi.search

pub fn (mut ls LanguageServer) references(params lsp.ReferenceParams) []lsp.Location {
	uri := params.text_document.uri.normalize()
	file := ls.get_file(uri) or { return [] }

	offset := file.find_offset(params.position)
	element := file.psi_file.find_element_at(offset) or {
		loglib.with_fields({
			'offset': offset.str()
		}).warn('Cannot find element')
		return []
	}

	references := search.references(element)
	return tform.elements_to_locations(references)
}
