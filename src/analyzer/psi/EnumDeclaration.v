module psi

import analyzer.psi.types

pub struct EnumDeclaration {
	PsiElementImpl
}

pub fn (e &EnumDeclaration) is_public() bool {
	modifiers := e.visibility_modifiers() or { return false }
	return modifiers.is_public()
}

pub fn (e &EnumDeclaration) get_type() types.Type {
	module_fqn := stubs_index.get_module_qualified_name(e.containing_file.path)
	return types.new_enum_type(e.name(), module_fqn)
}

pub fn (e EnumDeclaration) identifier() ?PsiElement {
	return e.find_child_by_type(.identifier)
}

pub fn (e EnumDeclaration) identifier_text_range() TextRange {
	if stub := e.get_stub() {
		return stub.identifier_text_range
	}

	identifier := e.identifier() or { return TextRange{} }
	return identifier.text_range()
}

pub fn (e EnumDeclaration) name() string {
	if stub := e.get_stub() {
		return stub.name
	}

	identifier := e.identifier() or { return '' }
	return identifier.get_text()
}

pub fn (e EnumDeclaration) doc_comment() string {
	if stub := e.get_stub() {
		return stub.comment
	}
	return extract_doc_comment(e)
}

pub fn (e EnumDeclaration) visibility_modifiers() ?&VisibilityModifiers {
	modifiers := e.find_child_by_type_or_stub(.visibility_modifiers)?
	if modifiers is VisibilityModifiers {
		return modifiers
	}
	return none
}

pub fn (e EnumDeclaration) fields() []PsiElement {
	if stub := e.get_stub() {
		return stub.get_children_by_type(.enum_field_definition).get_psi()
	}

	return e.find_children_by_type(.enum_field_definition)
}

pub fn (s &EnumDeclaration) attributes() []PsiElement {
	attributes := s.find_child_by_type_or_stub(.attributes) or { return [] }
	if attributes is Attributes {
		return attributes.attributes()
	}

	return []
}

pub fn (e EnumDeclaration) is_flag() bool {
	attributes := e.attributes()

	for attr in attributes {
		if attr is Attribute {
			keys := attr.keys()
			return 'flag' in keys
		}
	}

	return false
}

pub fn (_ EnumDeclaration) stub() {}
