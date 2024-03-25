module types

pub struct FixedArrayType {
pub:
	inner Type
	size  int
}

pub fn new_fixed_array_type(inner Type, size int) &FixedArrayType {
	return &FixedArrayType{
		inner: inner
		size: size
	}
}

pub fn (s &FixedArrayType) name() string {
	return '[${s.size}]${s.inner.name()}'
}

pub fn (s &FixedArrayType) qualified_name() string {
	return '[${s.size}]${s.inner.qualified_name()}'
}

pub fn (s &FixedArrayType) readable_name() string {
	return '[${s.size}]${s.inner.readable_name()}'
}

pub fn (s &FixedArrayType) module_name() string {
	return s.inner.module_name()
}

pub fn (s &FixedArrayType) accept(mut visitor TypeVisitor) {
	if !visitor.enter(s) {
		return
	}

	s.inner.accept(mut visitor)
}

pub fn (s &FixedArrayType) substitute_generics(name_map map[string]Type) Type {
	return new_fixed_array_type(s.inner.substitute_generics(name_map), s.size)
}
