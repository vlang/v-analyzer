module psi

pub struct Attributes {
	PsiElementImpl
}

fn (_ &Attributes) stub() {}

pub fn (n Attributes) attributes() []PsiElement {
	return n.find_children_by_type_or_stub(.attribute)
}
