module psi

import analyzer.psi.types

pub struct QualifiedType {
	PsiElementImpl
}

fn (n &QualifiedType) name() string {
	return ''
}

fn (n &QualifiedType) qualifier() ?PsiElement {
	return n.first_child_or_stub()
}

fn (n &QualifiedType) reference() PsiReference {
	ref_expr := n.right()
	return new_reference(n.containing_file, ref_expr as ReferenceExpressionBase, true)
}

fn (n &QualifiedType) resolve() ?PsiElement {
	return n.reference().resolve()
}

fn (n &QualifiedType) get_type() types.Type {
	right := n.right() or { return types.unknown_type }
	if right is ReferenceExpressionBase {
		resolved := right.resolve() or { return types.unknown_type }
		if resolved is PsiTypedElement {
			return resolved.get_type()
		}
	}

	return types.unknown_type
}

pub fn (n QualifiedType) left() ?PsiElement {
	return n.first_child_or_stub()
}

pub fn (n QualifiedType) right() ?PsiElement {
	return n.last_child_or_stub()
}
