module psi

pub struct Identifier {
	PsiElementImpl
}

pub fn (i Identifier) value() string {
	return i.get_text()
}

pub fn (i Identifier) name() string {
	return i.get_text()
}

pub fn (i Identifier) qualifier() ?PsiElement {
	parent := i.parent()?
	if parent is SelectorExpression {
		left := parent.left()?
		if left.is_equal(i) {
			return none
		}
		return left
	}
	return none
}

pub fn (i Identifier) reference() PsiReference {
	file := i.containing_file()
	return new_reference(file, i, false)
}

pub fn (i Identifier) resolve() ?PsiElement {
	if parent := i.parent() {
		if parent is PsiNamedElement {
			if ident := parent.identifier() {
				if ident.is_equal(i) {
					return parent as PsiElement
				}
			}
		}
	}
	return i.reference().resolve()
}
