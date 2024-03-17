module psi

import tree_sitter as ts

pub fn (node AstNode) parent_of_type(typ ts.NodeType) ?AstNode {
	mut res := node
	for {
		res = res.parent()?
		if res.type_name == typ {
			return res
		}
	}

	return none
}
