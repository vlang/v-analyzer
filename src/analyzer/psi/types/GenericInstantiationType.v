module types

pub struct GenericInstantiationType {
pub:
	inner          Type
	specialization []Type
}

pub fn new_generic_instantiation_type(inner Type, specialization []Type) &GenericInstantiationType {
	return &GenericInstantiationType{
		inner: inner
		specialization: specialization
	}
}

pub fn (s &GenericInstantiationType) name() string {
	return '${s.inner.name()}[${s.specialization.map(it.name()).join(', ')}]'
}

pub fn (s &GenericInstantiationType) qualified_name() string {
	return '${s.inner.qualified_name()}[${s.specialization.map(it.qualified_name()).join(', ')}]'
}

pub fn (s &GenericInstantiationType) readable_name() string {
	return '${s.inner.readable_name()}[${s.specialization.map(it.readable_name()).join(', ')}]'
}

pub fn (s &GenericInstantiationType) module_name() string {
	return s.inner.module_name()
}

pub fn (s &GenericInstantiationType) accept(mut visitor TypeVisitor) {
	if !visitor.enter(s) {
		return
	}

	s.inner.accept(mut visitor)

	for specialization in s.specialization {
		specialization.accept(mut visitor)
	}
}

pub fn (s &GenericInstantiationType) substitute_generics(name_map map[string]Type) Type {
	inner := s.inner.substitute_generics(name_map)
	specialization := s.specialization.map(it.substitute_generics(name_map))
	return new_generic_instantiation_type(inner, specialization)
}
