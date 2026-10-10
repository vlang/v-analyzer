module psi

import analyzer.psi.types

pub interface PsiTypedElement {
	get_type() types.Type
}
