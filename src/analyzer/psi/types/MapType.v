module types

pub struct MapType {
	BaseType
pub:
	key   Type
	value Type
}

pub fn new_map_type(module_name string, key Type, value Type) &MapType {
	return &MapType{
		key: key
		value: value
		module_name: module_name
	}
}

pub fn (s &MapType) name() string {
	return 'map[${s.key.name()}]${s.value.name()}'
}

pub fn (s &MapType) qualified_name() string {
	return 'map[${s.key.name()}]${s.value.qualified_name()}'
}

pub fn (s &MapType) readable_name() string {
	return 'map[${s.key.name()}]${s.value.readable_name()}'
}

pub fn (s &MapType) accept(mut visitor TypeVisitor) {
	if !visitor.enter(s) {
		return
	}

	s.key.accept(mut visitor)
	s.value.accept(mut visitor)
}

pub fn (s &MapType) substitute_generics(name_map map[string]Type) Type {
	return new_map_type(s.module_name, s.key.substitute_generics(name_map), s.value.substitute_generics(name_map))
}
