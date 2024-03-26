module server

import lsp
import loglib
import analyzer.psi
import server.tform

pub fn (mut ls LanguageServer) definition(params lsp.TextDocumentPositionParams) ?[]lsp.LocationLink {
	uri := params.text_document.uri.normalize()
	file := ls.get_file(uri)?

	offset := file.find_offset(params.position)
	element := file.psi_file.find_reference_at(offset) or {
		loglib.with_fields({
			'offset': offset.str()
		}).warn('Cannot find reference')
		return none
	}

	resolved := element.resolve() or {
		loglib.with_fields({
			'caller': @METHOD
			'name':   element.name()
		}).warn('Cannot resolve reference')
		return none
	}

	data := new_resolve_result(resolved.containing_file(), resolved) or { return [] }
	return [
		data.to_location_link(element.text_range()),
	]
}

struct ResolveResult {
pub:
	filepath string
	name     string
	range    psi.TextRange
}

pub fn new_resolve_result(containing_file &psi.PsiFile, element psi.PsiElement) ?ResolveResult {
	if element is psi.PsiNamedElement {
		text_range := element.identifier_text_range()
		return ResolveResult{
			range: text_range
			filepath: containing_file.path()
			name: element.name()
		}
	}

	return none
}

fn (r &ResolveResult) to_location_link(origin_selection_range psi.TextRange) lsp.LocationLink {
	range := tform.text_range_to_lsp_range(r.range)
	return lsp.LocationLink{
		target_uri: lsp.document_uri_from_path(r.filepath)
		origin_selection_range: tform.text_range_to_lsp_range(origin_selection_range)
		target_range: range
		target_selection_range: range
	}
}
