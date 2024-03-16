module psi

import v_tree_sitter as v

pub fn (node AstNode) parent_of_type(typ v.NodeType) ?AstNode {
	mut res := node
	for {
		res = res.parent()?
		if res.type_name == typ {
			return res
		}
	}

	return none
}
