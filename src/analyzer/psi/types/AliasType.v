module types

pub struct AliasType {
	BaseNamedType
pub:
	inner Type
}

pub fn new_alias_type(name string, module_name string, inner Type) &AliasType {
	return &AliasType{
		name: name
		module_name: module_name
		inner: inner
	}
}

pub fn (s &AliasType) accept(mut visitor TypeVisitor) {
	if !visitor.enter(s) {
		return
	}

	s.inner.accept(mut visitor)
}

pub fn (s &AliasType) substitute_generics(name_map map[string]Type) Type {
	return new_alias_type(s.name, s.module_name, s.inner.substitute_generics(name_map))
}
