module main

import tree_sitter as ts

fn main() {
	mut p := ts.new_parser[ts.NodeType](ts.type_factory)
	p.set_language(ts.language)

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
