module psi

import tree_sitter_v_api as api

pub fn (node AstNode) parent_of_type(typ api.NodeType) ?AstNode {
	mut res := node
	for {
		res = res.parent()?
		if res.type_name == typ {
			return res
		}
	}

	return none
}
