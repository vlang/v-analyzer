module psi

import analyzer.psi.types

pub struct FieldDeclaration {
	PsiElementImpl
}

pub fn (f &FieldDeclaration) is_embedded_definition() bool {
	return f.has_child_of_type(.embedded_definition)
}

pub fn (f &FieldDeclaration) is_public() bool {
	if owner := f.owner() {
		if owner is InterfaceDeclaration {
			return true // all interface fields are public by default
		}
	}

	_, is_pub := f.is_mutable_public()
	return is_pub
}

pub fn (f &FieldDeclaration) doc_comment() string {
	if stub := f.get_stub() {
		return stub.comment
	}

	if comment := f.find_child_by_type(.comment) {
		return comment.get_text().trim_string_left('//').trim(' \t')
	}

	return extract_doc_comment(f)
}

pub fn (f &FieldDeclaration) identifier() ?PsiElement {
	return f.find_child_by_type(.identifier)
}

pub fn (f FieldDeclaration) identifier_text_range() TextRange {
	if stub := f.get_stub() {
		return stub.identifier_text_range
	}

	identifier := f.identifier() or { return TextRange{} }
	return identifier.text_range()
}

pub fn (f &FieldDeclaration) name() string {
	if stub := f.get_stub() {
		return stub.name
	}

	identifier := f.identifier() or { return '' }
	return identifier.get_text()
}

pub fn (f &FieldDeclaration) get_type() types.Type {
	return infer_type(f)
}

pub fn (f &FieldDeclaration) owner() ?PsiElement {
	if struct_ := f.parent_of_type(.struct_declaration) {
		return struct_
	}
	return f.parent_of_type(.interface_declaration)
}

pub fn (f &FieldDeclaration) scope() ?&StructFieldScope {
	element := f.sibling_of_type_backward(.struct_field_scope)?
	if element is StructFieldScope {
		return element
	}
	return none
}

pub fn (f &FieldDeclaration) is_mutable_public() (bool, bool) {
	scope := f.scope() or { return false, false }
	return scope.is_mutable_public()
}

pub fn (_ FieldDeclaration) stub() {}
