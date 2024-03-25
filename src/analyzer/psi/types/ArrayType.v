module types

pub struct ArrayType {
pub:
	inner Type
}

pub fn new_array_type(inner Type) &ArrayType {
	return &ArrayType{
		inner: inner
	}
}

pub fn (s &ArrayType) name() string {
	return '[]${s.inner.name()}'
}

pub fn (s &ArrayType) qualified_name() string {
	return '[]${s.inner.qualified_name()}'
}

pub fn (s &ArrayType) readable_name() string {
	return '[]${s.inner.readable_name()}'
}

pub fn (s &ArrayType) module_name() string {
	return s.inner.module_name()
}

pub fn (s &ArrayType) accept(mut visitor TypeVisitor) {
	if !visitor.enter(s) {
		return
	}

	s.inner.accept(mut visitor)
}

pub fn (s &ArrayType) substitute_generics(name_map map[string]Type) Type {
	return new_array_type(s.inner.substitute_generics(name_map))
}
