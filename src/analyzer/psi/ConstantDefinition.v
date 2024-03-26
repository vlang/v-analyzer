module psi

import analyzer.parser
import analyzer.psi.types

pub struct ConstantDefinition {
	PsiElementImpl
}

pub fn (c &ConstantDefinition) is_public() bool {
	modifiers := c.visibility_modifiers() or { return false }
	return modifiers.is_public()
}

pub fn (c &ConstantDefinition) get_type() types.Type {
	expr := c.expression() or { return types.unknown_type }
	return infer_type(expr)
}

fn (c &ConstantDefinition) identifier() ?PsiElement {
	return c.find_child_by_type(.identifier)
}

pub fn (c ConstantDefinition) identifier_text_range() TextRange {
	if stub := c.get_stub() {
		return stub.identifier_text_range
	}

	identifier := c.identifier() or { return TextRange{} }
	return identifier.text_range()
}

pub fn (c ConstantDefinition) name() string {
	if stub := c.get_stub() {
		return stub.name
	}

	identifier := c.identifier() or { return '' }
	return identifier.get_text()
}

pub fn (c ConstantDefinition) doc_comment() string {
	if stub := c.get_stub() {
		return stub.comment
	}
	parent := c.parent() or { return '' }
	return extract_doc_comment(parent)
}

pub fn (c ConstantDefinition) visibility_modifiers() ?&VisibilityModifiers {
	if c.stub_based() {
		modifiers := c.prev_sibling_of_type(.visibility_modifiers)?
		if modifiers is VisibilityModifiers {
			return modifiers
		}
		return none
	}

	decl := c.parent()?
	modifiers := decl.find_child_by_type_or_stub(.visibility_modifiers)?
	if modifiers is VisibilityModifiers {
		return modifiers
	}
	return none
}

pub fn (c &ConstantDefinition) expression() ?PsiElement {
	if stub := c.get_stub() {
		// pretty hacky but it works
		res := parser.parse_code(stub.additional)
		root := res.tree.root_node()
		first_child := root.first_child()?
		next_first_child := first_child.first_child()?
		file := new_psi_file(c.containing_file.path, res.tree, res.source_text)
		return create_element(AstNode(next_first_child), file)
	}
	return c.last_child()
}

pub fn (_ ConstantDefinition) stub() {}
