module psi

pub interface PsiReference {
	element() PsiElement
	resolve() ?PsiElement
}
