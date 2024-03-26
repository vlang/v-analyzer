module psi

struct PsiTreeWalker {
mut:
	containing_file &PsiFile
	tree_walker     TreeWalker
}

pub fn (mut tw PsiTreeWalker) next() ?PsiElement {
	value := tw.tree_walker.next()?
	return create_element(value, tw.containing_file)
}

pub fn new_psi_tree_walker(root_node PsiElement) PsiTreeWalker {
	return PsiTreeWalker{
		tree_walker: new_tree_walker(root_node.node)
		containing_file: root_node.containing_file
	}
}
