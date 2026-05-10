module psi

pub struct BinaryExpression {
	PsiElementImpl
}

pub fn (n BinaryExpression) operator() string {
	operator_element := n.find_child_by_name('operator') or { return '' }
	return operator_element.get_text()
}

pub fn (n BinaryExpression) left() ?PsiElement {
	return n.find_child_by_name('left')
}

pub fn (n BinaryExpression) right() ?PsiElement {
	return n.find_child_by_name('right')
}
