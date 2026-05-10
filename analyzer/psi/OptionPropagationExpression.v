module psi

import analyzer.psi.types

pub struct OptionPropagationExpression {
	PsiElementImpl
}

fn (c &OptionPropagationExpression) get_type() types.Type {
	return infer_type(c)
}

pub fn (c OptionPropagationExpression) expression() ?PsiElement {
	return c.first_child()
}
