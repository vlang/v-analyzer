module psi

import analyzer.psi.types

pub struct OrBlockExpression {
	PsiElementImpl
}

fn (c &OrBlockExpression) get_type() types.Type {
	return infer_type(c)
}

pub fn (c OrBlockExpression) expression() ?PsiElement {
	return c.first_child()
}
