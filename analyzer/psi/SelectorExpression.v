module psi

import analyzer.psi.types

pub struct SelectorExpression {
	PsiElementImpl
}

fn (n &SelectorExpression) name() string {
	return ''
}

fn (n &SelectorExpression) qualifier() ?PsiElement {
	return n.first_child()
}

fn (n &SelectorExpression) reference() PsiReference {
	right := n.right() or { panic('no right element for SelectorExpression') }
	if right is FieldName {
		if child := right.reference_expression() {
			return new_reference(n.containing_file(), child, false)
		}
	}
	if right is ReferenceExpression {
		return new_reference(n.containing_file(), right, false)
	}
	if right is TypeReferenceExpression {
		return new_reference(n.containing_file(), right, true)
	}

	if right is Identifier {
		return new_reference(n.containing_file(), right, false)
	}
	ident := &Identifier{
		PsiElementImpl: new_psi_node(n.containing_file(), right.node())
	}
	return new_reference(n.containing_file(), ident, false)
}

fn (n &SelectorExpression) resolve() ?PsiElement {
	return n.reference().resolve()
}

fn (n &SelectorExpression) get_type() types.Type {
	right := n.right() or { return types.unknown_type }
	if right is ReferenceExpressionBase {
		resolved := right.resolve() or { return types.unknown_type }
		if resolved is PsiTypedElement {
			return resolved.get_type()
		}
	}

	return types.unknown_type
}

pub fn (n SelectorExpression) left() ?PsiElement {
	return n.first_child()
}

pub fn (n SelectorExpression) right() ?PsiElement {
	return n.last_child()
}
