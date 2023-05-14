module psi

pub struct StructDeclaration {
	PsiElementImpl
}

pub fn (s StructDeclaration) identifier() ?PsiElement {
	return s.find_child_by_type(.identifier) or {
		s.find_child_by_type(.builtin_type) or {
			s.find_child_by_type(.binded_type) or { return none }
		}
	}
}

pub fn (s StructDeclaration) name() string {
	identifier := s.identifier() or { return '' }
	return identifier.get_text()
}

pub fn (s StructDeclaration) doc_comment() string {
	return extract_doc_comment(s)
}

pub fn (s StructDeclaration) visibility_modifiers() ?&VisibilityModifiers {
	modifiers := s.find_child_by_type(.visibility_modifiers)?
	if modifiers is VisibilityModifiers {
		return modifiers
	}
	return none
}