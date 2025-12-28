module psi

import tree_sitter_v.bindings

pub struct TreeWalker {
mut:
	already_visited_children bool
	cursor                   bindings.TreeCursor[bindings.NodeType] @[required]
}

pub fn (mut tw TreeWalker) next() ?AstNode {
	if !tw.already_visited_children {
		if tw.cursor.to_first_child() {
			tw.already_visited_children = false
		} else if tw.cursor.next() {
			tw.already_visited_children = false
		} else {
			if !tw.cursor.to_parent() {
				return none
			}
			tw.already_visited_children = true
			return tw.next()
		}
	} else {
		if tw.cursor.next() {
			tw.already_visited_children = false
		} else {
			if !tw.cursor.to_parent() {
				return none
			}
			return tw.next()
		}
	}
	node := tw.cursor.current_node()?
	return node
}

pub fn new_tree_walker(root_node AstNode) TreeWalker {
	return TreeWalker{
		cursor: root_node.tree_cursor()
	}
}

@[inline]
pub fn (mut tw TreeWalker) to_first_child() bool {
	return tw.cursor.to_first_child()
}

@[inline]
pub fn (mut tw TreeWalker) to_parent() bool {
	return tw.cursor.to_parent()
}

@[inline]
pub fn (mut tw TreeWalker) next_sibling() bool {
	return tw.cursor.next()
}

@[inline]
pub fn (tw &TreeWalker) current_node() ?AstNode {
	return tw.cursor.current_node()
}

@[inline]
pub fn (mut tw TreeWalker) free() {
	unsafe { tw.cursor.raw_cursor.delete() }
}
