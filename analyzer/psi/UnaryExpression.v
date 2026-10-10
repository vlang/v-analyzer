module psi

pub struct UnaryExpression {
	PsiElementImpl
}

pub fn (n UnaryExpression) operator() string {
	operator_element := n.find_child_by_name('operator') or { return '' }
	return operator_element.get_text()
}

pub fn (n UnaryExpression) expression() ?PsiElement {
	return n.find_child_by_name('operand')
}
