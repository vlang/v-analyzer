module psi

pub struct FieldName {
	PsiElementImpl
}

pub fn (n FieldName) reference_expression() ?&ReferenceExpression {
	first_child := n.first_child()?
	if first_child is ReferenceExpression {
		return first_child
	}
	return none
}
