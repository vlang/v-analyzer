module psi

pub struct ArrayCreation {
	PsiElementImpl
	is_fixed bool
}

pub fn (n ArrayCreation) expressions() []PsiElement {
	children := n.children()
	return children.filter(it.element_type() != .unknown)
}
