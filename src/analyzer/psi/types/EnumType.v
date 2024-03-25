module types

pub struct EnumType {
	BaseNamedType
}

pub fn new_enum_type(name string, module_name string) &EnumType {
	return &EnumType{
		name: name
		module_name: module_name
	}
}

pub fn (s &EnumType) accept(mut visitor TypeVisitor) {
	if !visitor.enter(s) {
		return
	}
}

pub fn (s &EnumType) substitute_generics(_ map[string]Type) Type {
	return s
}
