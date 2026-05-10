module psi

pub struct Attribute {
	PsiElementImpl
}

fn (_ &Attribute) stub() {}

pub fn (n Attribute) expressions() []PsiElement {
	if stub := n.get_stub() {
		return stub.get_children_by_type(.attribute_expression).get_psi()
	}

	return n.find_children_by_type(.attribute_expression)
}

pub fn (n Attribute) keys() []string {
	expressions := n.expressions()
	if expressions.len == 0 {
		return []
	}

	return expressions.map(fn (expr PsiElement) string {
		if expr is AttributeExpression {
			return expr.value()
		}

		return ''
	}).filter(it != '')
}
