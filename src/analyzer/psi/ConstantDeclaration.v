module psi

pub struct ConstantDeclaration {
	PsiElementImpl
}

pub fn (n ConstantDeclaration) constants() []PsiElement {
	return n.find_children_by_type(.const_definition)
}
