module types

pub struct OptionType {
pub:
	inner    Type
	no_inner bool
}

pub fn new_option_type(inner Type, no_inner bool) &OptionType {
	return &OptionType{
		inner: inner
		no_inner: no_inner
	}
}

pub fn (s &OptionType) name() string {
	if s.no_inner {
		return '?'
	}
	return '?${s.inner.name()}'
}

pub fn (s &OptionType) qualified_name() string {
	if s.no_inner {
		return '?'
	}
	return '?${s.inner.qualified_name()}'
}

pub fn (s &OptionType) readable_name() string {
	if s.no_inner {
		return '?'
	}
	return '?${s.inner.readable_name()}'
}

pub fn (s &OptionType) module_name() string {
	return s.inner.module_name()
}

pub fn (s &OptionType) accept(mut visitor TypeVisitor) {
	if !visitor.enter(s) {
		return
	}

	s.inner.accept(mut visitor)
}

pub fn (s &OptionType) substitute_generics(name_map map[string]Type) Type {
	return new_option_type(s.inner.substitute_generics(name_map), s.no_inner)
}
