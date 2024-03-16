module main

import v_tree_sitter.tree_sitter
import tree_sitter_v
import time

fn main() {
	mut p := tree_sitter.new_parser[v_tree_sitter.NodeType](v_tree_sitter.type_factory)
	p.set_language(tree_sitter_v.language)

	code := '
fn foo() int {
	return 1
}
'.trim_indent()

	mut now := time.now()
	tree := p.parse_string(source: code)
	println('Parsed in ${time.since(now)}')

	root := tree.root_node()
	println(root)

	new_code := '
fn foo() int {
	return 2
}
'.trim_indent()

	now = time.now()
	new_tree := p.parse_string(source: new_code, tree: tree.raw_tree)
	println('Parsed in ${time.since(now)}')

	new_root := new_tree.root_node()
	println(new_root)
}
