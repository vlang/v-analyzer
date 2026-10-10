module psi

pub struct StructFieldScope {
	PsiElementImpl
}

pub fn (n StructFieldScope) is_mutable_public() (bool, bool) {
	text := n.get_text()
	return text.contains('mut'), text.contains('pub')
}

fn (_ &StructFieldScope) stub() {}
