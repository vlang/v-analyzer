module psi

import tree_sitter_v.bindings

pub struct AstCursor {
mut:
	raw_cursor bindings.TreeCursor[bindings.NodeType]
}

@[inline]
pub fn (mut c AstCursor) to_first_child() bool {
	return c.raw_cursor.to_first_child()
}

@[inline]
pub fn (mut c AstCursor) to_parent() bool {
	return c.raw_cursor.to_parent()
}

@[inline]
pub fn (mut c AstCursor) next() bool {
	return c.raw_cursor.next()
}

@[inline]
pub fn (c &AstCursor) current_node() ?AstNode {
	return c.raw_cursor.current_node()
}

@[inline]
pub fn (mut c AstCursor) free() {
	unsafe { c.raw_cursor.raw_cursor.delete() }
}
