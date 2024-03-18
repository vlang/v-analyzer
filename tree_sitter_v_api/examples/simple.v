module main

import tree_sitter_v_api as api

fn main() {
	mut p := api.new_parser[api.NodeType](api.type_factory)
	p.set_language(api.language)

	code := 'fn main() {}'
	tree := p.parse_string(source: code)
	root := tree.root_node()

	println(root)

	fc := root.first_child()?

	if fc.type_name == .function_declaration {
		if name_node := fc.child_by_field_name('name') {
			println('Found function: ${name_node.text(code)}')
			println('Position: ${name_node.range()}')
			println('Line: ${name_node.start_point().row}')
		}
	}
}
