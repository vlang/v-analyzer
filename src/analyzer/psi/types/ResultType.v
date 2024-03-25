module types

pub struct ResultType {
pub:
	inner    Type
	no_inner bool
}

pub fn new_result_type(inner Type, no_inner bool) &ResultType {
	return &ResultType{
		inner: inner
		no_inner: no_inner
	}
}

pub fn (s &ResultType) name() string {
	if s.no_inner {
		return '!'
	}
	return '!${s.inner.name()}'
}

pub fn (s &ResultType) qualified_name() string {
	if s.no_inner {
		return '!'
	}
	return '!${s.inner.qualified_name()}'
}

pub fn (s &ResultType) readable_name() string {
	if s.no_inner {
		return '!'
	}
	return '!${s.inner.readable_name()}'
}

pub fn (s &ResultType) module_name() string {
	return s.inner.module_name()
}

pub fn (s &ResultType) accept(mut visitor TypeVisitor) {
	if !visitor.enter(s) {
		return
	}

	s.inner.accept(mut visitor)
}

pub fn (s &ResultType) substitute_generics(name_map map[string]Type) Type {
	return new_result_type(s.inner.substitute_generics(name_map), s.no_inner)
}
