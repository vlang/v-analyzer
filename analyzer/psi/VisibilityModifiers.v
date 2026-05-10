module psi

pub struct VisibilityModifiers {
	PsiElementImpl
}

pub fn (n VisibilityModifiers) is_public() bool {
	return n.get_text() == 'pub'
}

fn (n &VisibilityModifiers) stub() {}
