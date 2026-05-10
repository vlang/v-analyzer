module psi

pub struct StringLiteral {
	PsiElementImpl
}

pub fn (n StringLiteral) content() string {
	text := n.get_text()
	return text[1..text.len - 1]
}
