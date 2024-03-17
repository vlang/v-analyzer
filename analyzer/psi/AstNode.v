module psi

import tree_sitter

pub fn (node AstNode) parent_of_type(typ tree_sitter.NodeType) ?AstNode {
	mut res := node
	for {
		res = res.parent()?
		if res.type_name == typ {
			return res
		}
	}

	return none
}
