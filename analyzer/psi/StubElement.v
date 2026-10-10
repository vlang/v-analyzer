module psi

// StubElement describes the interface of any stub.
pub interface StubElement {
	id() StubId
	name() string
	text() string
	receiver() string
	stub_type() StubType
	text_range() TextRange
	parent_stub() ?&StubElement
	first_child() ?&StubElement
	children_stubs() []StubElement
	get_child_by_type(typ StubType) ?StubElement
	has_child_of_type(typ StubType) bool
	get_children_by_type(typ StubType) []StubElement
	prev_sibling() ?&StubElement
	parent_of_type(typ StubType) ?StubElement
	get_psi() ?PsiElement
}

pub fn (elements []StubElement) get_psi() []PsiElement {
	mut result := []PsiElement{cap: elements.len}
	for element in elements {
		result << element.get_psi() or { continue }
	}
	return result
}

pub fn is_valid_stub(s StubElement) bool {
	if s is StubBase {
		return !isnil(s) && !isnil(s.stub_list)
	}
	return !isnil(s)
}
