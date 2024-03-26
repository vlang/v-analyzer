module psi

// inspect traverses an AST in depth-first order: It starts by calling
// `cb(node)`; node must not be `nil`. If call returns `true`, `inspect` invokes `cb`
// recursively for each of the non-nil children of node. Otherwise, `inspect` skips
// the children of node.
//
// Example:
// ```
// inspect(root, fn (node PsiElement) bool {
//   match node {
//     psi.FunctionDeclaration {
//       println('function ${node.name()}')
//     }
//     else {}
//   }
//   return true
// })
pub fn inspect(node PsiElement, cb fn (PsiElement) bool) {
	inspector := Inspector{
		cb: cb
	}
	node.accept(inspector)
}

struct Inspector {
	cb fn (PsiElement) bool = unsafe { nil }
}

fn (r &Inspector) visit_element(element PsiElement) {
	if !r.visit_element_impl(element) {
		return
	}
	mut child := element.first_child() or { return }
	for {
		child.accept(r)
		child = child.next_sibling() or { break }
	}
}

fn (i &Inspector) visit_element_impl(element PsiElement) bool {
	return i.cb(create_element(element.node, element.containing_file))
}
