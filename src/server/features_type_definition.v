module server

import lsp
import analyzer.psi
import analyzer.psi.types
import loglib

pub fn (mut ls LanguageServer) type_definition(params lsp.TextDocumentPositionParams) ?[]lsp.LocationLink {
	uri := params.text_document.uri.normalize()
	file := ls.get_file(uri)?

	offset := file.find_offset(params.position)
	element := file.psi_file.find_reference_at(offset) or {
		loglib.with_fields({
			'offset': offset.str()
		}).warn('Cannot find reference')
		return none
	}

	element_text_range := element.text_range()

	resolved := element.resolve() or {
		loglib.with_fields({
			'caller': @METHOD
			'name':   element.name()
		}).warn('Cannot resolve reference')
		return none
	}

	typ := types.unwrap_generic_instantiation_type(types.unwrap_pointer_type(psi.infer_type(resolved)))
	type_element := psi.find_element(typ.qualified_name())?

	data := new_resolve_result(type_element.containing_file(), type_element) or { return [] }
	return [
		data.to_location_link(element_text_range),
	]
}
