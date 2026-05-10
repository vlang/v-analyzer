module psi

pub struct InterfaceMethodDeclaration {
	PsiElementImpl
}

pub fn (_ InterfaceMethodDeclaration) is_public() bool {
	return true
}

pub fn (m InterfaceMethodDeclaration) identifier() ?PsiElement {
	return m.find_child_by_type(.identifier)
}

pub fn (m InterfaceMethodDeclaration) identifier_text_range() TextRange {
	if stub := m.get_stub() {
		return stub.identifier_text_range
	}

	identifier := m.identifier() or { return TextRange{} }
	return identifier.text_range()
}

pub fn (m InterfaceMethodDeclaration) signature() ?&Signature {
	signature := m.find_child_by_type_or_stub(.signature)?
	if signature is Signature {
		return signature
	}
	return none
}

pub fn (m InterfaceMethodDeclaration) name() string {
	if stub := m.get_stub() {
		return stub.name
	}

	identifier := m.identifier() or { return '' }
	return identifier.get_text()
}

pub fn (m &InterfaceMethodDeclaration) owner() ?&InterfaceDeclaration {
	parent := m.parent_of_type(.interface_declaration)?
	if parent is InterfaceDeclaration {
		return parent
	}
	return none
}

pub fn (m &InterfaceMethodDeclaration) scope() ?&StructFieldScope {
	element := m.sibling_of_type_backward(.struct_field_scope)?
	if element is StructFieldScope {
		return element
	}
	return none
}

pub fn (m InterfaceMethodDeclaration) doc_comment() string {
	if stub := m.get_stub() {
		return stub.comment
	}
	return extract_doc_comment(m)
}

pub fn (m InterfaceMethodDeclaration) fingerprint() string {
	signature := m.signature() or { return '' }
	count_params := signature.parameters().len
	has_return_type := if _ := signature.result() { true } else { false }
	return '${m.name()}:${count_params}:${has_return_type}'
}

pub fn (_ InterfaceMethodDeclaration) stub() {}
