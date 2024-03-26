module psi

import analyzer.psi.types

pub struct ResultPropagationExpression {
	PsiElementImpl
}

fn (c &ResultPropagationExpression) get_type() types.Type {
	return infer_type(c)
}

pub fn (c ResultPropagationExpression) expression() ?PsiElement {
	return c.first_child()
}
