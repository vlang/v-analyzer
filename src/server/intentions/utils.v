module intentions

import analyzer.psi

fn find_declaration_at_pos(file &psi.PsiFile, pos psi.Position) ?psi.PsiNamedElement {
	element := file.find_element_at_pos(pos) or { return none }
	if element !is psi.Identifier {
		return none
	}

	parent := element.parent() or { return none }
	if parent is psi.PsiNamedElement {
		return parent
	}

	if parent.node.type_name == .overridable_operator {
		grand := parent.parent() or { return none }
		if grand is psi.PsiNamedElement {
			return grand
		}
	}

	return none
}

fn find_reference_at_pos(file &psi.PsiFile, pos psi.Position) ?&psi.ReferenceExpression {
	element := file.find_element_at_pos(pos) or { return none }
	parent := element.parent() or { return none }
	if parent is psi.ReferenceExpression {
		return parent
	}

	return none
}
