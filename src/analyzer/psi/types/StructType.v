module types

pub const string_type = new_struct_type('string', 'builtin')
pub const builtin_array_type = new_struct_type('array', 'builtin')
pub const builtin_map_type = new_struct_type('map', 'builtin')
pub const array_init_type = new_struct_type('ArrayInit', 'stubs')
pub const chan_init_type = new_struct_type('ChanInit', 'stubs')
pub const flag_enum_type = new_enum_type('FlagEnum', 'stubs')
pub const any_type = new_alias_type('Any', 'stubs', unknown_type)

pub struct StructType {
	BaseNamedType
}

pub fn new_struct_type(name string, module_name string) &StructType {
	return &StructType{
		name:        name
		module_name: module_name
	}
}

pub fn (s &StructType) accept(mut visitor TypeVisitor) {
	if !visitor.enter(s) {
		return
	}
}

pub fn (s &StructType) substitute_generics(name_map map[string]Type) Type {
	return s
}
