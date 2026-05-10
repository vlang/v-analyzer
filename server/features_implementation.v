module server

import lsp
import loglib
import server.tform
import analyzer.psi
import analyzer.psi.search

pub fn (mut ls LanguageServer) implementation(params lsp.TextDocumentPositionParams) ?[]lsp.Location {
	uri := params.text_document.uri.normalize()
	file := ls.get_file(uri)?

	offset := file.find_offset(params.position)
	element := file.psi_file.find_element_at(offset) or {
		loglib.with_fields({
			'offset': offset.str()
		}).warn('Cannot find element')
		return none
	}

	if method := element.parent_of_type(.interface_method_definition) {
		if method is psi.InterfaceMethodDeclaration {
			methods := search.implementation_methods(*method)
			return tform.elements_to_locations(methods)
		}
	}

	if interface_declaration := element.parent_of_type(.interface_declaration) {
		if interface_declaration is psi.InterfaceDeclaration {
			implementations := search.implementations(*interface_declaration)
			return tform.elements_to_locations(implementations)
		}
	}

	if struct_declaration := element.parent_of_type(.struct_declaration) {
		if struct_declaration is psi.StructDeclaration {
			supers := search.supers(*struct_declaration)
			return tform.elements_to_locations(supers)
		}
	}

	if method := element.parent_of_type(.function_declaration) {
		if method is psi.FunctionOrMethodDeclaration {
			super_methods := search.super_methods(*method)
			return tform.elements_to_locations(super_methods)
		}
	}

	loglib.with_fields({
		'element':      element.get_text()
		'text_range':   element.text_range().str()
		'element_type': element.element_type().str()
	}).warn('Element is not inside an interface or struct declaration')

	return none
}
