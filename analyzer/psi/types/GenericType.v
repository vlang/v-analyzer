module types

pub struct GenericType {
	BaseNamedType
}

pub fn new_generic_type(name string) &GenericType {
	return &GenericType{
		name: name
	}
}

pub fn (s &GenericType) accept(mut visitor TypeVisitor) {
	if !visitor.enter(s) {
		return
	}
}

pub fn (s &GenericType) substitute_generics(name_map map[string]Type) Type {
	return name_map[s.name] or { return s }
}
