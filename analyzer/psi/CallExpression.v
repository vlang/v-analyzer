module psi

pub struct CallExpression {
	PsiElementImpl
}

pub fn (c CallExpression) resolve() ?PsiElement {
	ref_expr := c.find_child_by_type(.reference_expression) or { return none }

	if ref_expr is ReferenceExpression {
		resolved := ref_expr.resolve_local() or { return none }
		return resolved
	}

	return none
}

pub fn (c CallExpression) parameter_index_on_offset(offset u32) int {
	argument_list := c.find_child_by_type(.argument_list) or { return -1 }

	commas := argument_list.children().filter(it.get_text() == ',')

	count_commas_before := commas.filter(it.node.start_byte() < offset).len

	// arguments := argument_list.find_children_by_type(.argument)
	//
	// for i, argument in arguments {
	// 	if argument.node.start_byte() <= offset && offset <= argument.node.end_byte() {
	// 		return i
	// 	}
	// }
	//
	// rel_offset := offset - c.node.start_byte()
	// element := c.find_element_at(rel_offset) or { return -1 }
	// prev_element := element.prev_sibling() or { return -1 }

	return count_commas_before
}