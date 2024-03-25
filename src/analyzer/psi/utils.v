module psi

pub fn get_it_call(element PsiElement) ?&CallExpression {
	mut parent_call := element.parent_of_type(.call_expression)?
	if mut parent_call is CallExpression {
		for {
			expression := parent_call.expression() or { break }
			if expression.is_parent_of(element) {
				// when it used as expression of call
				// it.foo()
				parent_call = parent_call.parent_of_type(.call_expression) or { break }
				continue
			}

			break
		}
	}

	methods_names := ['filter', 'map', 'any', 'all']
	if mut parent_call is CallExpression {
		for !is_array_method_call(*parent_call, ...methods_names) {
			parent_call = parent_call.parent_of_type(.call_expression) or { break }
		}
	}

	if mut parent_call is CallExpression {
		return parent_call
	}

	return none
}

pub fn is_array_method_call(element CallExpression, names ...string) bool {
	ref_expression := element.ref_expression() or { return false }
	last_child := (ref_expression as PsiElement).last_child() or { return false }
	called_name := last_child.get_text()
	return called_name in names
}
