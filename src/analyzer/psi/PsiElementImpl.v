module psi

import tree_sitter_v.bindings

pub struct PsiElementImpl {
pub:
	node            AstNode // base node from Tree Sitter
	containing_file &PsiFile = unsafe { nil }
	// stubs related
	stub_id    StubId    = non_stubbed_element
	stubs_list &StubList = unsafe { nil }
}

pub fn new_psi_node(containing_file &PsiFile, node AstNode) PsiElementImpl {
	return PsiElementImpl{
		node:            node
		containing_file: containing_file
		stubs_list:      unsafe { nil }
	}
}

fn new_psi_node_from_stub(id StubId, stubs_list &StubList) PsiElementImpl {
	return PsiElementImpl{
		node:            AstNode{}
		containing_file: new_stub_psi_file(stubs_list.path, stubs_list)
		stub_id:         id
		stubs_list:      stubs_list
	}
}

pub fn (n &PsiElementImpl) stub_based() bool {
	return n.stub_id != non_stubbed_element && !isnil(n.stubs_list)
}

pub fn (n &PsiElementImpl) node() AstNode {
	return n.node
}

pub fn (n &PsiElementImpl) get_stub() ?&StubBase {
	if !n.stub_based() {
		return none
	}

	return n.stubs_list.get_stub(n.stub_id)
}

pub fn (n &PsiElementImpl) stub_list() &StubList {
	return n.stubs_list
}

pub fn (n &PsiElementImpl) element_type() bindings.NodeType {
	if stub := n.get_stub() {
		return stub.element_type()
	}
	if isnil(n.node) {
		return .unknown
	}
	return n.node.type_name
}

pub fn (n &PsiElementImpl) containing_file() &PsiFile {
	if n.stub_based() {
		path := n.stubs_list.path
		return new_stub_psi_file(path, n.stubs_list)
	}

	return n.containing_file
}

pub fn (n &PsiElementImpl) is_equal(other PsiElement) bool {
	if n.element_type() != other.element_type() {
		return false
	}

	if n.text_range() != other.text_range() {
		return false
	}

	return n.get_text() == other.get_text()
}

pub fn (n &PsiElementImpl) accept(visitor PsiElementVisitor) {
	visitor.visit_element(n)
}

pub fn (n &PsiElementImpl) accept_mut(mut visitor MutablePsiElementVisitor) {
	visitor.visit_element(n)
}

pub fn (n &PsiElementImpl) find_element_at(offset u32) ?PsiElement {
	start_byte := if n.node.type_name == .source_file { u32(0) } else { n.node.start_byte() }
	abs_offset := start_byte + offset
	el := n.node.descendant_for_byte_range(abs_offset, abs_offset)?
	return create_element(el, n.containing_file)
}

pub fn (n &PsiElementImpl) find_reference_at(offset u32) ?PsiElement {
	element := n.find_element_at(offset)?
	if element is ReferenceExpressionBase {
		return element as PsiElement
	}
	if element is Identifier {
		parent := element.parent()?
		if parent is ReferenceExpressionBase {
			return parent as PsiElement
		}
	}
	return none
}

pub fn (n &PsiElementImpl) parent() ?PsiElement {
	if stub := n.get_stub() {
		if isnil(stub) {
			return none
		}

		parent := stub.parent_stub()?
		if isnil(parent) {
			return none
		}

		if parent.stub_type() == .root {
			return none
		}

		if is_valid_stub(parent) {
			return parent.get_psi()
		}
		return none
	}

	parent := n.node.parent()?
	return create_element(parent, n.containing_file)
}

pub fn (n &PsiElementImpl) parent_nth(depth int) ?PsiElement {
	parent := n.node.parent_nth(depth)?
	return create_element(parent, n.containing_file)
}

pub fn (n &PsiElementImpl) parent_of_type(typ bindings.NodeType) ?PsiElement {
	mut res := PsiElement(n)
	for {
		res = res.parent()?
		if res.element_type() == typ {
			return res
		}
	}

	return none
}

pub fn (n &PsiElementImpl) parent_of_any_type(types ...bindings.NodeType) ?PsiElement {
	mut res := PsiElement(n)
	for {
		res = res.parent()?
		element_type := res.element_type()
		if element_type in types {
			return res
		}
	}

	return none
}

pub fn (n &PsiElementImpl) inside(typ bindings.NodeType) bool {
	mut res := PsiElement(n)
	for {
		res = res.parent() or { return false }
		if res.element_type() == typ {
			return true
		}
	}

	return false
}

pub fn (n &PsiElementImpl) is_parent_of(element PsiElement) bool {
	if stub := n.get_stub() {
		if element_stub := element.get_stub() {
			if stub.stub_list.path != element_stub.stub_list.path {
				return false
			}
		}
	}

	mut parent := element.parent() or { return false }

	for {
		if parent.is_equal(n) {
			return true
		}
		parent = parent.parent() or { break }
	}

	return false
}

pub fn (n &PsiElementImpl) sibling_of_type_backward(typ bindings.NodeType) ?PsiElement {
	mut res := PsiElement(n)
	for {
		res = res.prev_sibling_or_stub()?
		if res.element_type() == typ {
			return res
		}
	}

	return none
}

pub fn (n &PsiElementImpl) parent_of_type_or_self(typ bindings.NodeType) ?PsiElement {
	if n.node.type_name == typ {
		return create_element(n.node, n.containing_file)
	}
	mut parent := n.parent()?
	if parent.element_type() == typ {
		return parent
	}

	for {
		parent = parent.parent()?
		if parent.element_type() == typ {
			return parent
		}
	}

	return none
}

pub fn (n &PsiElementImpl) children() []PsiElement {
	if stub := n.get_stub() {
		children := stub.children_stubs()
		return children.get_psi()
	}

	mut result := []PsiElement{}
	mut child := n.node.first_child() or { return [] }
	for {
		result << create_element(child, n.containing_file)
		child = child.next_sibling() or { break }
	}
	return result
}

pub fn (n &PsiElementImpl) named_children() []PsiElement {
	if stub := n.get_stub() {
		children := stub.children_stubs()
		return children.get_psi()
	}

	mut result := []PsiElement{}
	mut child := n.node.first_child() or { return [] }
	for {
		if child.type_name != .unknown {
			result << create_element(child, n.containing_file)
		}
		child = child.next_sibling() or { break }
	}
	return result
}

pub fn (n &PsiElementImpl) first_child() ?PsiElement {
	child := n.node.first_child()?
	return create_element(child, n.containing_file)
}

pub fn (n &PsiElementImpl) first_child_or_stub() ?PsiElement {
	if stub := n.get_stub() {
		child := stub.first_child()?
		return child.get_psi()
	}

	child := n.node.first_child()?
	return create_element(child, n.containing_file)
}

pub fn (n &PsiElementImpl) last_child() ?PsiElement {
	child := n.node.last_child()?
	return create_element(child, n.containing_file)
}

pub fn (n &PsiElementImpl) last_child_or_stub() ?PsiElement {
	if stub := n.get_stub() {
		child := stub.last_child()?
		return child.get_psi()
	}

	child := n.node.last_child()?
	return create_element(child, n.containing_file)
}

pub fn (n &PsiElementImpl) next_sibling() ?PsiElement {
	sibling := n.node.next_sibling()?
	return create_element(sibling, n.containing_file)
}

pub fn (n &PsiElementImpl) next_sibling_or_stub() ?PsiElement {
	if stub := n.get_stub() {
		sibling := stub.next_sibling()?
		if is_valid_stub(sibling) {
			return sibling.get_psi()
		}
		return none
	}

	return n.next_sibling()
}

pub fn (n &PsiElementImpl) prev_sibling() ?PsiElement {
	sibling := n.node.prev_sibling()?
	return create_element(sibling, n.containing_file)
}

pub fn (n &PsiElementImpl) prev_sibling_of_type(typ bindings.NodeType) ?PsiElement {
	mut res := PsiElement(n)
	for {
		res = res.prev_sibling_or_stub()?
		if res.element_type() == typ {
			return res
		}
	}

	return none
}

pub fn (n &PsiElementImpl) prev_sibling_or_stub() ?PsiElement {
	if stub := n.get_stub() {
		sibling := stub.prev_sibling()?
		if is_valid_stub(sibling) {
			return sibling.get_psi()
		}
		return none
	}

	return n.prev_sibling()
}

pub fn (n &PsiElementImpl) find_child_by_type(typ bindings.NodeType) ?PsiElement {
	ast_node := n.node.first_node_by_type(typ)?
	return create_element(ast_node, n.containing_file)
}

pub fn (n &PsiElementImpl) has_child_of_type(typ bindings.NodeType) bool {
	if stub := n.get_stub() {
		return stub.has_child_of_type(node_type_to_stub_type(typ))
	}

	if _ := n.node.first_node_by_type(typ) {
		return true
	}

	return false
}

pub fn (n &PsiElementImpl) find_child_by_type_or_stub(typ bindings.NodeType) ?PsiElement {
	if stub := n.get_stub() {
		child := stub.get_child_by_type(node_type_to_stub_type(typ))?
		return child.get_psi()
	}

	ast_node := n.node.first_node_by_type(typ)?
	return create_element(ast_node, n.containing_file)
}

pub fn (n &PsiElementImpl) find_child_by_name(name string) ?PsiElement {
	ast_node := n.node.child_by_field_name(name)?
	return create_element(ast_node, n.containing_file)
}

pub fn (n &PsiElementImpl) find_children_by_type(typ bindings.NodeType) []PsiElement {
	mut result := []PsiElement{}
	mut child := n.node.first_child() or { return [] }
	for {
		if child.type_name == typ {
			result << create_element(child, n.containing_file)
		}
		child = child.next_sibling() or { break }
	}
	return result
}

pub fn (n &PsiElementImpl) find_children_by_type_or_stub(typ bindings.NodeType) []PsiElement {
	if stub := n.get_stub() {
		return stub.get_children_by_type(node_type_to_stub_type(typ)).get_psi()
	}

	mut result := []PsiElement{}
	mut child := n.node.first_child() or { return [] }
	for {
		if child.type_name == typ {
			result << create_element(child, n.containing_file)
		}
		child = child.next_sibling() or { break }
	}
	return result
}

pub fn (n &PsiElementImpl) find_last_child_by_type(typ bindings.NodeType) ?PsiElement {
	ast_node := n.node.last_node_by_type(typ)?
	return create_element(ast_node, n.containing_file)
}

pub fn (n &PsiElementImpl) get_text() string {
	if stub := n.get_stub() {
		return stub.text
	}

	return n.node.text(n.containing_file.source_text)
}

pub fn (n &PsiElementImpl) text_matches(value string) bool {
	if stub := n.get_stub() {
		return stub.text == value
	}

	return n.node.text_matches(n.containing_file.source_text, value)
}

pub fn (n &PsiElementImpl) text_range() TextRange {
	if stub := n.get_stub() {
		return stub.text_range
	}

	return TextRange{
		line:       int(n.node.start_point().row)
		column:     int(n.node.start_point().column)
		end_line:   int(n.node.end_point().row)
		end_column: int(n.node.end_point().column)
	}
}

pub fn (n &PsiElementImpl) text_length() int {
	if stub := n.get_stub() {
		range := stub.text_range
		return range.end_column - range.column
	}

	return int(n.node.text_length())
}
