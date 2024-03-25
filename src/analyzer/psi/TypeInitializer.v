module psi

import analyzer.psi.types

pub struct TypeInitializer {
	PsiElementImpl
}

pub fn (n &TypeInitializer) get_type() types.Type {
	return infer_type(n)
}

pub fn (n &TypeInitializer) element_list() []PsiElement {
	body := n.find_child_by_name('body') or { return [] }
	element_list := body.find_child_by_type(.element_list) or { return [] }
	return element_list.named_children()
}
