module psi

pub struct ImportDeclaration {
	PsiElementImpl
}

pub fn (n &ImportDeclaration) spec() ?&ImportSpec {
	spec := n.find_child_by_type(.import_spec)?
	if spec is ImportSpec {
		return spec
	}
	return none
}

fn (n &ImportDeclaration) stub() {}
