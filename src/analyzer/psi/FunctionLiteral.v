module psi

pub struct FunctionLiteral {
	PsiElementImpl
}

pub fn (f FunctionLiteral) signature() ?&Signature {
	signature := f.find_child_by_type_or_stub(.signature)?
	if signature is Signature {
		return signature
	}
	return none
}
