module server

import lsp
import analyzer.psi
import server.tform

pub fn (mut ls LanguageServer) document_symbol(params lsp.DocumentSymbolParams) ![]lsp.DocumentSymbol {
	uri := params.text_document.uri.normalize()
	mut file_symbols := []lsp.DocumentSymbol{}

	elements := stubs_index.get_all_elements_from_file(uri.path())
	for element in elements {
		file_symbols << document_symbol_presentation(element) or { continue }
	}

	return file_symbols
}

fn document_symbol_presentation(element psi.PsiElement) ?lsp.DocumentSymbol {
	full_text_range := element.text_range()
	if element is psi.PsiNamedElement {
		if element.name() == '' {
			return none
		}

		identifier_text_range := element.identifier_text_range()
		children := symbol_children(element)
		return lsp.DocumentSymbol{
			name: name_presentation(element)
			detail: detail_presentation(element)
			kind: symbol_kind(element as psi.PsiElement)?
			range: tform.text_range_to_lsp_range(full_text_range)
			selection_range: tform.text_range_to_lsp_range(identifier_text_range)
			children: children
		}
	}

	return none
}

fn symbol_kind(element psi.PsiElement) ?lsp.SymbolKind {
	match element {
		psi.FunctionOrMethodDeclaration {
			if _ := element.receiver() {
				return .method
			}
			return .function
		}
		psi.StructDeclaration {
			return .struct_
		}
		psi.InterfaceDeclaration {
			return .interface_
		}
		psi.InterfaceMethodDeclaration {
			return .method
		}
		psi.FieldDeclaration {
			return .field
		}
		psi.EnumDeclaration {
			return .enum_
		}
		psi.EnumFieldDeclaration {
			return .enum_member
		}
		psi.ConstantDefinition {
			return .constant
		}
		psi.TypeAliasDeclaration {
			return .type_parameter
		}
		else {}
	}
	return none
}

fn name_presentation(element psi.PsiNamedElement) string {
	name := element.name()

	if element is psi.FunctionOrMethodDeclaration {
		mut parts := []string{}

		if receiver := element.receiver() {
			parts << receiver.get_text()
		}

		parts << name

		if parameters := element.generic_parameters() {
			parts << parameters.text_presentation()
		}

		return parts.join(' ')
	}
	if element is psi.GenericParametersOwner {
		parameters := element.generic_parameters() or { return name }
		return name + parameters.text_presentation()
	}
	return name
}

fn detail_presentation(element psi.PsiNamedElement) string {
	if element is psi.FunctionOrMethodDeclaration {
		if signature := element.signature() {
			return 'fn ' + signature.get_text()
		}
	}
	if element is psi.FieldDeclaration {
		return element.get_type().readable_name()
	}
	if element is psi.InterfaceMethodDeclaration {
		if signature := element.signature() {
			return signature.get_text()
		}
	}
	if element is psi.ConstantDefinition {
		return element.get_type().readable_name()
	}
	if element is psi.EnumFieldDeclaration {
		return '= ' + element.value_presentation(true)
	}
	return ''
}

fn symbol_children(element psi.PsiNamedElement) []lsp.DocumentSymbol {
	mut children := []psi.PsiElement{}
	if element is psi.StructDeclaration {
		children << element.own_fields()
	} else if element is psi.EnumDeclaration {
		children << element.fields()
	} else if element is psi.InterfaceDeclaration {
		children << element.fields()
		children << element.methods()
	}

	mut symbols := []lsp.DocumentSymbol{cap: children.len}
	for child in children {
		symbols << document_symbol_presentation(child) or { continue }
	}
	return symbols
}
