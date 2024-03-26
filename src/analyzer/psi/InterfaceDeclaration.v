module psi

import analyzer.psi.types

pub struct InterfaceDeclaration {
	PsiElementImpl
}

pub fn (s &InterfaceDeclaration) generic_parameters() ?&GenericParameters {
	generic_parameters := s.find_child_by_type_or_stub(.generic_parameters)?
	if generic_parameters is GenericParameters {
		return generic_parameters
	}
	return none
}

pub fn (s &InterfaceDeclaration) is_public() bool {
	modifiers := s.visibility_modifiers() or { return false }
	return modifiers.is_public()
}

pub fn (s &InterfaceDeclaration) module_name() string {
	return stubs_index.get_module_qualified_name(s.containing_file.path)
}

pub fn (s &InterfaceDeclaration) get_type() types.Type {
	return types.new_interface_type(s.name(), s.module_name())
}

pub fn (s &InterfaceDeclaration) attributes() []PsiElement {
	attributes := s.find_child_by_type(.attributes) or { return [] }
	if attributes is Attributes {
		return attributes.attributes()
	}

	return []
}

pub fn (s InterfaceDeclaration) identifier() ?PsiElement {
	return s.find_child_by_type(.identifier)
}

pub fn (s InterfaceDeclaration) identifier_text_range() TextRange {
	if stub := s.get_stub() {
		return stub.identifier_text_range
	}

	identifier := s.identifier() or { return TextRange{} }
	return identifier.text_range()
}

pub fn (s InterfaceDeclaration) name() string {
	if stub := s.get_stub() {
		return stub.name
	}

	identifier := s.identifier() or { return '' }
	return identifier.get_text()
}

pub fn (s InterfaceDeclaration) doc_comment() string {
	if stub := s.get_stub() {
		return stub.comment
	}
	return extract_doc_comment(s)
}

pub fn (s InterfaceDeclaration) visibility_modifiers() ?&VisibilityModifiers {
	modifiers := s.find_child_by_type_or_stub(.visibility_modifiers)?
	if modifiers is VisibilityModifiers {
		return modifiers
	}
	return none
}

pub fn (s InterfaceDeclaration) fields() []PsiElement {
	mut fields := s.own_fields()

	embedded_types := s.embedded_definitions()
		.map(types.unwrap_alias_type(it.get_type()))
		.filter(it is types.InterfaceType)

	for embedded_type in embedded_types {
		if interface_ := find_interface(embedded_type.qualified_name()) {
			fields << interface_.fields()
		}
	}

	return fields
}

pub fn (s InterfaceDeclaration) own_fields() []PsiElement {
	field_declarations := s.find_children_by_type_or_stub(.struct_field_declaration)
	mut result := []PsiElement{cap: field_declarations.len}
	for field_declaration in field_declarations {
		if first_child := field_declaration.first_child_or_stub() {
			if first_child.element_type() != .embedded_definition {
				result << field_declaration
			}
		}
	}
	return result
}

pub fn (s InterfaceDeclaration) embedded_definitions() []&EmbeddedDefinition {
	field_declarations := s.find_children_by_type_or_stub(.struct_field_declaration)
	mut result := []&EmbeddedDefinition{cap: field_declarations.len}
	for field_declaration in field_declarations {
		if embedded_definition := field_declaration.find_child_by_type_or_stub(.embedded_definition) {
			if embedded_definition is EmbeddedDefinition {
				result << embedded_definition
			}
		}
	}
	return result
}

pub fn (s InterfaceDeclaration) methods() []PsiElement {
	return s.find_children_by_type_or_stub(.interface_method_definition)
}

pub fn (s InterfaceDeclaration) find_method(name string) ?&InterfaceMethodDeclaration {
	methods := s.methods()
	for method in methods {
		if method is InterfaceMethodDeclaration {
			if name == method.name() {
				return method
			}
		}
	}

	return none
}

pub fn (_ InterfaceDeclaration) stub() {}
