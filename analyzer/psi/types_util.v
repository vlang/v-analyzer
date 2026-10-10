module psi

import analyzer.psi.types

pub fn own_methods_list(typ types.Type) []PsiElement {
	module_name := typ.module_name()
	name := typ.name()
	if module_name == '' || name == '' {
		return []
	}

	key := '${module_name}.${name}'
	methods := stubs_index.get_elements_by_name(.methods, key)
	return methods
}

pub fn fields_list(typ types.Type) []PsiElement {
	name := typ.qualified_name()
	structs := stubs_index.get_elements_by_name(.structs, name)
	if structs.len == 0 {
		return []
	}

	struct_ := structs.first()
	if struct_ is StructDeclaration {
		return struct_.fields()
	}
	return []
}

pub fn methods_list(typ types.Type) []PsiElement {
	mut result := own_methods_list(typ)

	unwrapped := types.unwrap_alias_type(types.unwrap_pointer_type(typ))
	if unwrapped.qualified_name() != typ.qualified_name() {
		// if after unwrapping alias type we get another type, we need
		// to collect their methods as well.
		result << own_methods_list(unwrapped)
	}

	if typ is types.InterfaceType {
		if interface_ := find_interface(typ.qualified_name()) {
			embedded_types := interface_.embedded_definitions().map(it.get_type())
			for embedded_type in embedded_types {
				result << methods_list(embedded_type)
			}
		}
	}

	if typ is types.StructType {
		if struct_ := find_struct(typ.qualified_name()) {
			embedded_types := struct_.embedded_definitions().map(it.get_type())
			for embedded_type in embedded_types {
				result << methods_list(embedded_type)
			}
		}
	}

	return result
}

pub fn find_method(typ types.Type, name string) ?PsiElement {
	methods := methods_list(typ)
	for method in methods {
		if method is PsiNamedElement {
			if method.name() == name {
				return method as PsiElement
			}
		}
	}
	return none
}

pub fn static_methods_list(typ types.Type) []PsiElement {
	module_name := typ.module_name()
	name := typ.name()
	if module_name == '' || name == '' {
		return []
	}

	key := '${module_name}.${name}'
	methods := stubs_index.get_elements_by_name(.static_methods, key)
	return methods
}
