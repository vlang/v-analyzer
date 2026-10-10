module psi

pub struct AttributeExpression {
	PsiElementImpl
}

pub fn (n &AttributeExpression) value() string {
	if stub := n.get_stub() {
		if first_child := stub.first_child() {
			return first_child.text()
		}
		return ''
	}

	if first_child := n.first_child() {
		if first_child is ValueAttribute {
			return first_child.value()
		}
	}

	return ''
}

fn (_ &AttributeExpression) stub() {}
