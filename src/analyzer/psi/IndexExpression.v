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

pub fn (c IndexExpression) resolve() ?PsiElement {
	expr := if selector_expr := c.find_child_by_type(.selector_expression) {
		selector_expr as ReferenceExpressionBase
	} else if ref_expr := c.find_child_by_type(.reference_expression) {
		ref_expr as ReferenceExpressionBase
	} else {
		return none
	}

	if expr is ReferenceExpressionBase {
		resolved := expr.resolve()?
		return resolved
	}

	return none
}
