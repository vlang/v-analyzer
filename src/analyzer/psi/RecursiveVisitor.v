module psi

pub struct RecursiveVisitorBase {
}

fn (r &RecursiveVisitorBase) visit_element(element PsiElement) {
	if !r.visit_element_impl(element) {
		return
	}
	mut child := element.first_child() or { return }
	for {
		child.accept(r)
		child = child.next_sibling() or { break }
	}
}

fn (_ &RecursiveVisitorBase) visit_element_impl(element PsiElement) bool {
	return true
}
