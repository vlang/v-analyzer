module psi

pub struct ForStatement {
	PsiElementImpl
}

pub fn (n ForStatement) var_definitions() []PsiElement {
	if range_clause := n.find_child_by_type(.range_clause) {
		var_definition_list := range_clause.find_child_by_type(.var_definition_list) or {
			return []
		}
		return var_definition_list.find_children_by_type(.var_definition)
	}

	if for_clause := n.find_child_by_type(.for_clause) {
		initializer := for_clause.first_child() or { return [] }
		if initializer.element_type() == .simple_statement {
			decl := initializer.first_child() or { return [] }
			list := decl.first_child() or { return [] }
			definition := list.first_child() or { return [] }
			return [definition]
		}
	}

	return []
}
