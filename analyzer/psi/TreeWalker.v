module psi

import tree_sitter

struct TreeWalker {
mut:
	already_visited_children bool
	cursor                   tree_sitter.TreeCursor[tree_sitter.NodeType] @[required]
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
