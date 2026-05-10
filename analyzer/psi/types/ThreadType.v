module types

pub struct ThreadType {
	inner Type
}

pub fn new_thread_type(inner Type) &ThreadType {
	return &ThreadType{
		inner: inner
	}
}

pub fn (s &ThreadType) name() string {
	return 'thread ${s.inner.name()}'
}

pub fn (s &ThreadType) qualified_name() string {
	return 'thread ${s.inner.qualified_name()}'
}

pub fn (s &ThreadType) readable_name() string {
	return 'thread ${s.inner.readable_name()}'
}

pub fn (s &ThreadType) module_name() string {
	return s.inner.module_name()
}

pub fn (s &ThreadType) accept(mut visitor TypeVisitor) {
	if !visitor.enter(s) {
		return
	}

	s.inner.accept(mut visitor)
}

pub fn (s &ThreadType) substitute_generics(name_map map[string]Type) Type {
	return new_thread_type(s.inner.substitute_generics(name_map))
}
