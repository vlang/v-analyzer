module psi

pub struct IfExpression {
	PsiElementImpl
}

pub fn (n IfExpression) var_definition() ?&VarDefinition {
	decl := n.find_child_by_type(.var_declaration)?
	list := decl.first_child()?
	expr := list.first_child()?
	if expr is VarDefinition {
		return expr
	}
	if expr is MutExpression {
		var := expr.last_child()?
		if var is VarDefinition {
			return var
		}
	}
	return none
}

pub fn (n IfExpression) block() ?&Block {
	block := n.find_child_by_type(.block)?
	return if block is Block { block } else { none }
}

pub fn (n IfExpression) else_branch() ?PsiElement {
	return n.find_child_by_type(.else_branch)?.last_child()
}
