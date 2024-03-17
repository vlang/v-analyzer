module psi

import tree_sitter

pub interface PsiNamedElement {
	parent_of_type(typ tree_sitter.NodeType) ?PsiElement
	identifier_text_range() TextRange
	identifier() ?PsiElement
	name() string
	is_public() bool
}
