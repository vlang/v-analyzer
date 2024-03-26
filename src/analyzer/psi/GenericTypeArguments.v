module psi

import analyzer.psi.types

pub struct GenericTypeArguments {
	PsiElementImpl
}

pub fn (n GenericTypeArguments) types() []types.Type {
	plain_types := n.find_children_by_type(.plain_type)

	inferer := TypeInferer{}
	mut visited := map[string]types.Type{}

	mut arg_types := []types.Type{cap: plain_types.len}
	for plain_type in plain_types {
		arg_types << inferer.convert_type(plain_type, mut visited)
	}

	return arg_types
}
