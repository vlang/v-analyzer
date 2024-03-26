module psi

pub struct ValueAttribute {
	PsiElementImpl
}

pub fn (n ValueAttribute) value() string {
	return n.get_text()
}

fn (_ &ValueAttribute) stub() {}
