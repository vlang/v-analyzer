module search

import analyzer.psi

// implementation_methods returns all methods that implement the given interface method.
pub fn implementation_methods(method psi.InterfaceMethodDeclaration) []psi.PsiElement {
	mut result := []psi.PsiElement{}
	owner := method.owner() or { return [] }
	structs := implementations(owner)

	for struct_ in structs {
		if struct_ is psi.StructDeclaration {
			struct_method := psi.find_method(struct_.get_type(), method.name()) or { continue }
			result << struct_method
		}
	}

	return result
}
