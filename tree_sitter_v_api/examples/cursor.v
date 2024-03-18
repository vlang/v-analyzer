module main

import tree_sitter_v_api as api

fn main() {
	mut p := api.new_parser[api.NodeType](api.type_factory)
	p.set_language(api.language)

	code := '
fn foo() int {
	return 1
}
'.trim_indent()

	tree := p.parse_string(source: code)
	root := tree.root_node()

	mut cursor := root.tree_cursor()
	cursor.to_first_child() // go to all the children of the root node
	cursor.to_first_child() // go to the first child of the function node

	for {
		node := cursor.current_node() or { break }

		println('Node "${node.type_name}" with text: ' + node.text(code))

		if !cursor.next() {
			break
		}
	}
}
