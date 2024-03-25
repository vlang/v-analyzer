module psi

import analyzer.psi.types

pub struct ParameterDeclaration {
	PsiElementImpl
}

fn (p &ParameterDeclaration) stub() {}

pub fn (_ &ParameterDeclaration) is_public() bool {
	return true
}

pub fn (p &ParameterDeclaration) get_type() types.Type {
	return infer_type(p)
}

pub fn (p &ParameterDeclaration) identifier() ?PsiElement {
	return p.find_child_by_type(.identifier)
}

pub fn (p &ParameterDeclaration) identifier_text_range() TextRange {
	if stub := p.get_stub() {
		return stub.identifier_text_range
	}

	identifier := p.identifier() or { return TextRange{} }
	return identifier.text_range()
}

pub fn (p &ParameterDeclaration) name() string {
	if stub := p.get_stub() {
		return stub.name
	}

	identifier := p.identifier() or { return '' }
	return identifier.get_text()
}

pub fn (p &ParameterDeclaration) mutability_modifiers() ?&MutabilityModifiers {
	modifiers := p.find_child_by_type_or_stub(.mutability_modifiers)?
	if modifiers is MutabilityModifiers {
		return modifiers
	}
	return none
}

pub fn (p &ParameterDeclaration) is_mutable() bool {
	mods := p.mutability_modifiers() or { return false }
	return mods.is_mutable()
}
