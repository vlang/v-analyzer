module psi

import tree_sitter_v_api as api

pub interface PsiNamedElement {
	parent_of_type(typ api.NodeType) ?PsiElement
	identifier_text_range() TextRange
	identifier() ?PsiElement
	name() string
	is_public() bool
}
