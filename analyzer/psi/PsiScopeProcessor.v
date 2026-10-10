module psi

pub interface PsiScopeProcessor {
mut:
	execute(element PsiElement) bool
}
