module psi

import strconv
import analyzer.psi.types

pub struct Literal {
	PsiElementImpl
}

fn (n &Literal) get_type() types.Type {
	return infer_type(n)
}

fn (n &Literal) value() i64 {
	text := n.get_text()
	if text.starts_with('0x') {
		return strconv.parse_int(text[2..], 16, 64) or { 0 }
	} else if text.starts_with('0b') {
		return strconv.parse_int(text[2..], 2, 64) or { 0 }
	} else if text.starts_with('0o') {
		return strconv.parse_int(text[2..], 8, 64) or { 0 }
	}

	return text.int()
}
