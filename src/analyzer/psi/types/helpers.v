module types

pub fn unwrap_pointer_type(typ Type) Type {
	if typ is PointerType {
		return typ.inner
	}
	return typ
}

pub fn unwrap_alias_type(typ Type) Type {
	if typ is AliasType {
		return typ.inner
	}
	return typ
}

pub fn unwrap_channel_type(typ Type) Type {
	if typ is ChannelType {
		return typ.inner
	}
	return typ
}

pub fn unwrap_result_or_option_type(typ Type) Type {
	if typ is ResultType {
		return typ.inner
	}
	if typ is OptionType {
		return typ.inner
	}
	return typ
}

pub fn unwrap_result_or_option_type_if(typ Type, condition bool) Type {
	if condition {
		return unwrap_result_or_option_type(typ)
	}
	return typ
}

pub fn unwrap_generic_instantiation_type(typ Type) Type {
	if typ is GenericInstantiationType {
		return typ.inner
	}
	return typ
}

pub fn is_builtin_array_type(typ Type) bool {
	if typ is StructType {
		return typ.qualified_name() == builtin_array_type.qualified_name()
	}
	return false
}

pub fn is_builtin_map_type(typ Type) bool {
	if typ is StructType {
		return typ.qualified_name() == builtin_map_type.qualified_name()
	}
	return false
}

struct IsGenericVisitor {
mut:
	is_generic bool
}

fn (mut v IsGenericVisitor) enter(typ Type) bool {
	if typ is GenericType {
		v.is_generic = true
		return false
	}
	return true
}

pub fn is_generic(typ Type) bool {
	if typ is GenericType {
		return true
	}

	mut v := IsGenericVisitor{}
	typ.accept(mut v)
	return v.is_generic
}
