module psi

pub struct MatchExpression {
	PsiElementImpl
}

pub fn (n MatchExpression) expression() ?PsiElement {
	return n.find_child_by_name('condition')
}

pub fn (n MatchExpression) arms() []PsiElement {
	arms := n.find_child_by_type(.match_arms) or { return [] }
	mut arm_list := arms.find_children_by_type(.match_arm)
	arm_list << arms.find_children_by_type(.match_else_arm_clause)
	return arm_list
}

pub fn (n MatchExpression) else_branch() ?PsiElement {
	return n.find_child_by_name('else_branch')
}
