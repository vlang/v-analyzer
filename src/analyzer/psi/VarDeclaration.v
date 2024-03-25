module psi

pub struct VarDeclaration {
	PsiElementImpl
}

fn (v VarDeclaration) index_of(def VarDefinition) int {
	first_child := v.first_child() or { return -1 }
	children := first_child.children()
		.filter(it is VarDefinition || it is MutExpression)
		.map(fn (it PsiElement) PsiElement {
			if it is MutExpression {
				return it.last_child() or { return it }
			}
			return it
		})

	for i, definition in children {
		if definition.is_equal(def) {
			return i
		}
	}
	return -1
}

fn (v VarDeclaration) initializer_of(def VarDefinition) ?PsiElement {
	index := v.index_of(def)
	if index == -1 {
		return none
	}

	expressions := v.expressions()
	if expressions.len == 1 && expressions.first() is CallExpression {
		return expressions.first()
	}

	if index >= expressions.len {
		return none
	}

	return expressions[index]
}

pub fn (v VarDeclaration) vars() []PsiElement {
	first_child := v.first_child() or { return [] }
	return first_child
		.children()
		.filter(it is VarDefinition || it is MutExpression)
		.map(fn (it PsiElement) PsiElement {
			if it is MutExpression {
				return it.last_child() or { return it }
			}
			return it
		})
}

fn (v VarDeclaration) expressions() []PsiElement {
	last_child := v.last_child() or { return [] }
	return last_child.children()
}
