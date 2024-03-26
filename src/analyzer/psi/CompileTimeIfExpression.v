module psi

pub struct CompileTimeIfExpression {
	PsiElementImpl
}

pub fn (n CompileTimeIfExpression) block() ?&Block {
	block := n.find_child_by_type(.block)?
	if block is Block {
		return block
	}
	return none
}

pub fn (n CompileTimeIfExpression) else_branch() ?PsiElement {
	return n.find_child_by_name('else_branch')
}
