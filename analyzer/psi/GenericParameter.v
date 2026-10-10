module psi

@[heap]
pub struct GenericParameter {
	PsiElementImpl
}

pub fn (n &GenericParameter) identifier_text_range() TextRange {
	if stub := n.get_stub() {
		return stub.identifier_text_range
	}

	identifier := n.identifier() or { return TextRange{} }
	return identifier.text_range()
}

pub fn (n &GenericParameter) identifier() ?PsiElement {
	return n.find_child_by_type(.identifier)
}

pub fn (n &GenericParameter) name() string {
	if stub := n.get_stub() {
		return stub.name
	}

	identifier := n.identifier() or { return '' }
	return identifier.get_text()
}

pub fn (_ &GenericParameter) is_public() bool {
	return true
}

fn (_ &GenericParameter) stub() {}
