module psi

import analyzer.psi.types

pub struct IndexExpression {
	PsiElementImpl
}

fn (c &IndexExpression) get_type() types.Type {
	return infer_type(c)
}

pub fn (c IndexExpression) expression() ?PsiElement {
	return c.first_child()
}
