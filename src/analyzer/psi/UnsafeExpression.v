module psi

pub struct UnsafeExpression {
	PsiElementImpl
}

pub fn (n UnsafeExpression) block() ?&Block {
	block := n.find_child_by_type(.block)?
	if block is Block {
		return block
	}
	return none
}
