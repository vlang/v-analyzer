module server

import lsp
import loglib
import server.tform
import analyzer.psi.search

pub fn (mut ls LanguageServer) rename(params lsp.RenameParams) !lsp.WorkspaceEdit {
	uri := params.text_document.uri.normalize()
	file := ls.get_file(uri) or { return error('cannot rename element from not opened file') }

	offset := file.find_offset(params.position)
	element := file.psi_file.find_element_at(offset) or {
		loglib.with_fields({
			'offset': offset.str()
		}).warn('Cannot find element')
		return error('cannot find element at ' + offset.str())
	}

	references := search.references(element, include_declaration: true)
	edits := tform.elements_to_text_edits(references, params.new_name)

	return lsp.WorkspaceEdit{
		changes: {
			uri: edits
		}
	}
}
