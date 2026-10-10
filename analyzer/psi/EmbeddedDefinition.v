module psi

import analyzer.psi.types

pub struct EmbeddedDefinition {
	PsiElementImpl
}

pub fn (n &EmbeddedDefinition) owner() ?PsiElement {
	if struct_ := n.parent_of_type(.struct_declaration) {
		return struct_
	}
	return n.parent_of_type(.interface_declaration)
}

pub fn (n &EmbeddedDefinition) identifier_text_range() TextRange {
	if stub := n.get_stub() {
		return stub.identifier_text_range
	}

	identifier := n.identifier() or { return TextRange{} }
	return identifier.text_range()
}

pub fn (n &EmbeddedDefinition) identifier() ?PsiElement {
	if qualified_type := n.find_child_by_type_or_stub(.qualified_type) {
		return qualified_type.last_child_or_stub()
	}
	if generic_type := n.find_child_by_type_or_stub(.generic_type) {
		return generic_type.first_child_or_stub()
	}
	if ref_expression := n.find_child_by_type_or_stub(.type_reference_expression) {
		return ref_expression.first_child_or_stub()
	}
	return none
}

pub fn (n &EmbeddedDefinition) name() string {
	if stub := n.get_stub() {
		return stub.name
	}

	identifier := n.identifier() or { return '' }
	return identifier.get_text()
}

pub fn (_ &EmbeddedDefinition) is_public() bool {
	return true
}

pub fn (n &EmbeddedDefinition) get_type() types.Type {
	return infer_type(n)
}

fn (_ &EmbeddedDefinition) stub() {}
