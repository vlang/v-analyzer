module psi

import tree_sitter as ts

pub interface PsiNamedElement {
	parent_of_type(typ ts.NodeType) ?PsiElement
	identifier_text_range() TextRange
	identifier() ?PsiElement
	name() string
	is_public() bool
}
