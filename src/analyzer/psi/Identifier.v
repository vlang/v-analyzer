module psi

pub struct Identifier {
	PsiElementImpl
}

pub fn (i Identifier) value() string {
	return i.get_text()
}
