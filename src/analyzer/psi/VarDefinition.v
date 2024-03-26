module psi

import analyzer.psi.types

pub struct VarDefinition {
	PsiElementImpl
}

pub fn (_ &VarDefinition) is_public() bool {
	return true
}

pub fn (n &VarDefinition) identifier() ?PsiElement {
	return n.find_child_by_type(.identifier)
}

pub fn (n &VarDefinition) identifier_text_range() TextRange {
	identifier := n.identifier() or { return TextRange{} }
	return identifier.text_range()
}

pub fn (n &VarDefinition) name() string {
	identifier := n.identifier() or { return '' }
	return identifier.get_text()
}

pub fn (n &VarDefinition) declaration() ?&VarDeclaration {
	if parent := n.parent_nth(2) {
		if parent is VarDeclaration {
			return parent
		}
	}
	if parent := n.parent_nth(3) {
		if parent is VarDeclaration {
			return parent
		}
	}
	return none
}

pub fn (n &VarDefinition) get_type() types.Type {
	return infer_type(n)
}

pub fn (n &VarDefinition) mutability_modifiers() ?&MutabilityModifiers {
	if mut_expr := n.parent() {
		if mut_expr.node.type_name == .mutable_expression {
			modifiers := mut_expr.find_child_by_type(.mutability_modifiers)?
			if modifiers is MutabilityModifiers {
				return modifiers
			}
		}
	}

	return none
}

pub fn (n &VarDefinition) is_mutable() bool {
	mods := n.mutability_modifiers() or {
		if first_child := n.first_child() {
			if first_child.text_matches('mut') {
				return true
			}
		}

		if grand := n.parent_nth(4) {
			if grand.element_type() == .for_clause {
				// variable inside for loop initializer is mutable by default
				return true
			}
		}
		return false
	}
	return mods.is_mutable()
}
