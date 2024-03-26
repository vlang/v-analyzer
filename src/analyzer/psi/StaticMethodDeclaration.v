module psi

import analyzer.psi.types

pub struct StaticMethodDeclaration {
	PsiElementImpl
}

pub fn (f &StaticMethodDeclaration) generic_parameters() ?&GenericParameters {
	generic_parameters := f.find_child_by_type_or_stub(.generic_parameters)?
	if generic_parameters is GenericParameters {
		return generic_parameters
	}
	return none
}

pub fn (f &StaticMethodDeclaration) is_public() bool {
	modifiers := f.visibility_modifiers() or { return false }
	return modifiers.is_public()
}

fn (f &StaticMethodDeclaration) get_type() types.Type {
	signature := f.signature() or { return types.unknown_type }
	return signature.get_type()
}

pub fn (f StaticMethodDeclaration) identifier() ?PsiElement {
	return f.find_child_by_type(.identifier)
}

pub fn (f StaticMethodDeclaration) identifier_text_range() TextRange {
	if stub := f.get_stub() {
		return stub.identifier_text_range
	}

	identifier := f.identifier() or { return TextRange{} }
	return identifier.text_range()
}

pub fn (f StaticMethodDeclaration) signature() ?&Signature {
	signature := f.find_child_by_type_or_stub(.signature)?
	if signature is Signature {
		return signature
	}
	return none
}

pub fn (f StaticMethodDeclaration) name() string {
	if stub := f.get_stub() {
		return stub.name
	}

	identifier := f.identifier() or { return '' }
	return identifier.get_text()
}

pub fn (f StaticMethodDeclaration) doc_comment() string {
	if stub := f.get_stub() {
		return stub.comment
	}
	return extract_doc_comment(f)
}

pub fn (f StaticMethodDeclaration) receiver_type() types.Type {
	receiver := f.receiver() or { return types.unknown_type }
	return receiver.get_type()
}

pub fn (f StaticMethodDeclaration) receiver() ?&StaticReceiver {
	element := f.find_child_by_type_or_stub(.static_receiver)?
	if element is StaticReceiver {
		return element
	}
	return none
}

pub fn (f StaticMethodDeclaration) visibility_modifiers() ?&VisibilityModifiers {
	modifiers := f.find_child_by_type_or_stub(.visibility_modifiers)?
	if modifiers is VisibilityModifiers {
		return modifiers
	}
	return none
}

pub fn (f StaticMethodDeclaration) owner() ?PsiElement {
	receiver := f.receiver()?
	typ := receiver.get_type()
	unwrapped := types.unwrap_generic_instantiation_type(types.unwrap_pointer_type(typ))
	if unwrapped is types.InterfaceType {
		return *find_interface(unwrapped.qualified_name())?
	}
	if unwrapped is types.StructType {
		return *find_struct(unwrapped.qualified_name())?
	}
	if unwrapped is types.AliasType {
		return *find_alias(unwrapped.qualified_name())?
	}
	return none
}

pub fn (f StaticMethodDeclaration) fingerprint() string {
	signature := f.signature() or { return '' }
	count_params := signature.parameters().len
	has_return_type := if _ := signature.result() { true } else { false }
	return '${f.name()}:${count_params}:${has_return_type}'
}

pub fn (_ StaticMethodDeclaration) stub() {}
