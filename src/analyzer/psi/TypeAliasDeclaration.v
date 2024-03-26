module psi

import analyzer.psi.types

pub struct TypeAliasDeclaration {
	PsiElementImpl
}

pub fn (a &TypeAliasDeclaration) get_type() types.Type {
	return types.new_interface_type(a.name(), a.module_name())
}

pub fn (a &TypeAliasDeclaration) generic_parameters() ?&GenericParameters {
	generic_parameters := a.find_child_by_type_or_stub(.generic_parameters)?
	if generic_parameters is GenericParameters {
		return generic_parameters
	}
	return none
}

pub fn (a &TypeAliasDeclaration) is_public() bool {
	modifiers := a.visibility_modifiers() or { return false }
	return modifiers.is_public()
}

pub fn (a &TypeAliasDeclaration) module_name() string {
	return stubs_index.get_module_qualified_name(a.containing_file.path)
}

pub fn (a TypeAliasDeclaration) doc_comment() string {
	if stub := a.get_stub() {
		return stub.comment
	}
	return extract_doc_comment(a)
}

pub fn (a &TypeAliasDeclaration) types() []PlainType {
	inner_types := a.find_children_by_type_or_stub(.plain_type)
	mut result := []PlainType{cap: inner_types.len}
	for type_ in inner_types {
		if type_ is PlainType {
			result << type_
		}
	}
	return result
}

pub fn (a TypeAliasDeclaration) identifier() ?PsiElement {
	return a.find_child_by_type(.identifier)
}

pub fn (a &TypeAliasDeclaration) identifier_text_range() TextRange {
	if stub := a.get_stub() {
		return stub.identifier_text_range
	}

	identifier := a.identifier() or { return TextRange{} }
	return identifier.text_range()
}

pub fn (a TypeAliasDeclaration) name() string {
	if stub := a.get_stub() {
		return stub.name
	}

	identifier := a.identifier() or { return '' }
	return identifier.get_text()
}

pub fn (a TypeAliasDeclaration) visibility_modifiers() ?&VisibilityModifiers {
	modifiers := a.find_child_by_type_or_stub(.visibility_modifiers)?
	if modifiers is VisibilityModifiers {
		return modifiers
	}
	return none
}

fn (_ &TypeAliasDeclaration) stub() {}
