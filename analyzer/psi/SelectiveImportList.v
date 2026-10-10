module psi

pub struct SelectiveImportList {
	PsiElementImpl
}

pub fn (n &SelectiveImportList) symbols() []ReferenceExpression {
	children := n.find_children_by_type_or_stub(.reference_expression)
	mut res := []ReferenceExpression{cap: children.len}
	for child in children {
		if child is ReferenceExpression {
			res << child
		}
	}
	return res
}

fn (n &SelectiveImportList) stub() {}
