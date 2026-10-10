module psi

import analyzer.psi.types

pub struct TypeReferenceExpression {
	PsiElementImpl
}

fn (_ &TypeReferenceExpression) stub() {}

pub fn (_ TypeReferenceExpression) is_public() bool {
	return true
}

pub fn (r TypeReferenceExpression) identifier() ?PsiElement {
	return r.first_child()
}

pub fn (r &TypeReferenceExpression) identifier_text_range() TextRange {
	if stub := r.get_stub() {
		return stub.identifier_text_range
	}

	identifier := r.identifier() or { return TextRange{} }
	return identifier.text_range()
}

pub fn (r TypeReferenceExpression) name() string {
	if stub := r.get_stub() {
		return stub.text
	}

	identifier := r.identifier() or { return '' }
	return identifier.get_text()
}

pub fn (r TypeReferenceExpression) qualifier() ?PsiElement {
	parent := r.parent()?

	if parent is QualifiedType {
		left := parent.left()?
		if left.is_equal(r) {
			return none
		}

		return left
	}

	return none
}

pub fn (r TypeReferenceExpression) reference() PsiReference {
	return new_reference(r.containing_file, r, true)
}

pub fn (r TypeReferenceExpression) resolve() ?PsiElement {
	return r.reference().resolve()
}

pub fn (r TypeReferenceExpression) get_type() types.Type {
	element := r.resolve() or { return types.unknown_type }

	if element is PsiTypedElement {
		return element.get_type()
	}

	return types.unknown_type
}
