module psi

pub struct Range {
	PsiElementImpl
}

pub fn (n Range) left() ?PsiElement {
	return n.first_child()
}

pub fn (n Range) right() ?PsiElement {
	return n.last_child()
}

pub fn (n Range) inclusive() bool {
	op := n.operator() or { return false }
	return op.get_text() == '...'
}

pub fn (n Range) operator() ?PsiElement {
	left := n.left()?
	return left.next_sibling()
}
