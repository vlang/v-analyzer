module psi

import analyzer.psi.types

pub struct Receiver {
	PsiElementImpl
}

pub fn (r &Receiver) is_public() bool {
	return true
}

fn (r &Receiver) identifier_text_range() TextRange {
	if stub := r.get_stub() {
		return stub.identifier_text_range
	}

	identifier := r.identifier() or { return TextRange{} }
	return identifier.text_range()
}

fn (r &Receiver) identifier() ?PsiElement {
	return r.find_child_by_type(.identifier)
}

pub fn (r &Receiver) name() string {
	if stub := r.get_stub() {
		return stub.name
	}

	identifier := r.identifier() or { return '' }
	return identifier.get_text()
}

pub fn (r &Receiver) type_element() ?PsiElement {
	if stub := r.get_stub() {
		if receiver_stub := stub.get_child_by_type(.plain_type) {
			psi := receiver_stub.get_psi()?
			if psi is PlainType {
				return psi
			}
		}
		return none
	}

	return r.find_child_by_type(.plain_type)
}

pub fn (r &Receiver) get_type() types.Type {
	return infer_type(r)
}

pub fn (r &Receiver) mutability_modifiers() ?&MutabilityModifiers {
	modifiers := r.find_child_by_type_or_stub(.mutability_modifiers)?
	if modifiers is MutabilityModifiers {
		return modifiers
	}
	return none
}

pub fn (r &Receiver) is_mutable() bool {
	mods := r.mutability_modifiers() or { return false }
	return mods.is_mutable()
}

fn (_ &Receiver) stub() {}
