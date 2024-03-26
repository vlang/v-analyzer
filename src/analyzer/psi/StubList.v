module psi

// StubList describes a way to store all stubs in a specific file.
// Storing stubs as a table is more efficient than storing them as a tree, and
// also makes it easier to serialize stubs to a file.
@[heap]
pub struct StubList {
pub mut:
	// module_fqn is the fully qualified name of the module from the root, eg `foo.bar` or `foo.bar.baz`,
	// if no module is defined then the empty string.
	module_fqn string
	path       string // absolute path to the file
	index_map  map[StubId]&StubBase
	child_map  map[StubId][]int
}

fn (s StubList) root() &StubBase {
	return s.index_map[0] or {
		// should never happen
		return new_root_stub('unknown file')
	}
}

fn (mut s StubList) add_stub(mut stub StubBase, parent &StubElement) {
	stub_id := s.index_map.len
	stub.id = stub_id
	s.index_map[stub_id] = stub

	// add stub to parent's children
	parent_id := if parent is StubBase { parent.id } else { -1 }
	mut parent_children := s.child_map[parent_id]
	parent_children << stub_id
	s.child_map[parent_id] = parent_children
}

fn (s &StubList) first_child(id StubId) ?&StubElement {
	stub := s.get_stub(id)?
	children_ids := s.child_map[stub.id()]
	if children_ids.len == 0 {
		return none
	}

	child_id := children_ids.first()
	return s.index_map[child_id] or { return none }
}

fn (s &StubList) last_child(id StubId) ?&StubElement {
	stub := s.get_stub(id)?
	children_ids := s.child_map[stub.id()]
	if children_ids.len == 0 {
		return none
	}

	child_id := children_ids.last()
	return s.index_map[child_id] or { return none }
}

fn (s &StubList) get_child_by_type(id StubId, typ StubType) ?StubElement {
	stub_ids := s.child_map[id]
	for stub_id in stub_ids {
		stub := s.index_map[stub_id] or { continue }
		if stub.stub_type == typ {
			return stub
		}
	}
	return none
}

fn (s &StubList) has_child_of_type(id StubId, typ StubType) bool {
	stub_ids := s.child_map[id]
	for stub_id in stub_ids {
		stub := s.index_map[stub_id] or { continue }
		if stub.stub_type == typ {
			return true
		}
	}
	return false
}

fn (s &StubList) get_children_stubs(id StubId) []StubElement {
	stub_ids := s.child_map[id]
	mut stubs := []StubElement{cap: stub_ids.len}
	for stub_id in stub_ids {
		stubs << s.index_map[stub_id] or { continue }
	}
	return stubs
}

fn (s &StubList) prev_sibling(id StubId) ?&StubElement {
	stub := s.get_stub(id)?
	parent := stub.parent_stub()?

	children_ids := s.child_map[parent.id()]
	index := children_ids.index(id)
	if index == 0 || index == -1 {
		return none
	}

	prev_id := children_ids[index - 1]
	return s.index_map[prev_id] or { return none }
}

fn (s &StubList) next_sibling(id StubId) ?&StubElement {
	stub := s.get_stub(id)?
	parent := stub.parent_stub()?

	children_ids := s.child_map[parent.id()]
	index := children_ids.index(id)
	if index == 0 || index == -1 {
		return none
	}

	prev_id := children_ids[index + 1] or { return none }
	return s.index_map[prev_id] or { return none }
}

fn (s &StubList) get_stub(id StubId) ?&StubBase {
	stub := s.index_map[id] or { return none }
	if isnil(stub) {
		return none
	}
	return stub
}
