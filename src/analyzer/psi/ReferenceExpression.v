module psi

import analyzer.psi.types

pub struct ReferenceExpression {
	PsiElementImpl
}

pub fn (r &ReferenceExpression) is_public() bool {
	return true
}

pub fn (r ReferenceExpression) identifier() ?PsiElement {
	return r.first_child()
}

pub fn (r &ReferenceExpression) identifier_text_range() TextRange {
	if stub := r.get_stub() {
		return stub.identifier_text_range
	}

	identifier := r.identifier() or { return TextRange{} }
	return identifier.text_range()
}

pub fn (r &ReferenceExpression) name() string {
	if stub := r.get_stub() {
		return stub.text
	}

	identifier := r.identifier() or { return '' }
	return identifier.get_text()
}

pub fn (r ReferenceExpression) qualifier() ?PsiElement {
	parent := r.parent()?

	if parent is SelectorExpression {
		left := parent.left()?
		if left.is_equal(r) {
			return none
		}

		return left
	}

	return none
}

pub fn (r ReferenceExpression) reference() PsiReference {
	if parent := r.parent() {
		if parent is ValueAttribute {
			return new_attribute_reference(r.containing_file, r)
		}
	}

	return new_reference(r.containing_file, r, false)
}

pub fn (r ReferenceExpression) resolve() ?PsiElement {
	return r.reference().resolve()
}

pub fn (r ReferenceExpression) get_type() types.Type {
	return infer_type(r)
}
