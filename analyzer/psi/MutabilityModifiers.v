module psi

pub struct MutabilityModifiers {
	PsiElementImpl
}

pub fn (n MutabilityModifiers) is_mutable() bool {
	children := n.children()
	return children.any(it.get_text() == 'mut')
}
