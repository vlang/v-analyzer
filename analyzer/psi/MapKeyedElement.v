module psi

pub struct MapKeyedElement {
	PsiElementImpl
}

pub fn (n MapKeyedElement) key() ?PsiElement {
	return n.first_child()
}

pub fn (n MapKeyedElement) value() ?PsiElement {
	return n.last_child()
}
