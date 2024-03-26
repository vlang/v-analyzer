module psi

import analyzer.psi.types

pub struct GlobalVarDefinition {
	PsiElementImpl
}

fn (_ &GlobalVarDefinition) stub() {}

pub fn (_ &GlobalVarDefinition) is_public() bool {
	return true
}

pub fn (n &GlobalVarDefinition) identifier() ?PsiElement {
	return n.find_child_by_type(.identifier)
}

pub fn (n &GlobalVarDefinition) identifier_text_range() TextRange {
	if stub := n.get_stub() {
		return stub.identifier_text_range
	}

	identifier := n.identifier() or { return TextRange{} }
	return identifier.text_range()
}

pub fn (n &GlobalVarDefinition) name() string {
	if stub := n.get_stub() {
		return stub.name
	}

	identifier := n.identifier() or { return '' }
	return identifier.get_text()
}

pub fn (n &GlobalVarDefinition) get_type() types.Type {
	return infer_type(n)
}
