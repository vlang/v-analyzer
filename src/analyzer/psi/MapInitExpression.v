module psi

pub struct MapInitExpression {
	PsiElementImpl
}

pub fn (n MapInitExpression) key_values() []PsiElement {
	return n.find_children_by_type(.map_keyed_element)
}
