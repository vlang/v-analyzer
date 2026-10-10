module psi

import analyzer.psi.types

pub struct StaticReceiver {
	PsiElementImpl
}

pub fn (_ &StaticReceiver) is_public() bool {
	return true
}

fn (r &StaticReceiver) identifier_text_range() TextRange {
	if stub := r.get_stub() {
		return stub.identifier_text_range
	}

	identifier := r.identifier() or { return TextRange{} }
	return identifier.text_range()
}

fn (r &StaticReceiver) identifier() ?PsiElement {
	return r.find_child_by_type(.identifier)
}

pub fn (r &StaticReceiver) name() string {
	if stub := r.get_stub() {
		return stub.name
	}

	identifier := r.identifier() or { return '' }
	return identifier.get_text()
}

pub fn (r &StaticReceiver) get_type() types.Type {
	return infer_type(r.first_child())
}

fn (_ &StaticReceiver) stub() {}
