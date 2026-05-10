module search

import analyzer.psi

// implementations returns all implementations of the given interface
//
// Search algorithm:
// 1. Having interface methods and fields, we look for all methods and fields in structures with the same fingerprint.
//    method fingerprint is the name + the number of parameters + the presence of a return value.
//    field fingerprint is the name.
//
//    During indexing, we already collect all methods and fields into `.methods_fingerprint`
//    and `.fields_fingerprint` indices, so searching for such methods and fields has a complexity of O(1).
//
// 2. For each received method and field, find the parent structure and add it to the list of candidates.
//
// 3. For each candidate, check that it implements all methods and fields of the interface.
pub fn implementations(iface psi.InterfaceDeclaration) []psi.PsiElement {
	methods := iface.methods()
	fields := iface.fields()

	if methods.len == 0 && fields.len == 0 {
		return []
	}

	candidates := candidates_by_methods_and_fields(methods, fields)
	if candidates.len == 0 {
		return []
	}

	mut result := map[string]psi.PsiElement{}

	for candidate in candidates {
		name := candidate.name()
		if name in result {
			// don't check one candidate several times
			continue
		}

		if is_implemented_by_type(methods, fields, candidate as psi.PsiElement) {
			result[name] = candidate as psi.PsiElement
		}
	}

	return result.values()
}

fn is_implemented_by_type(iface_methods []psi.PsiElement, iface_fields []psi.PsiElement, symbol psi.PsiElement) bool {
	symbol_type := if symbol is psi.PsiTypedElement {
		symbol.get_type()
	} else {
		return false
	}

	symbol_methods := psi.methods_list(symbol_type)
	if symbol_methods.len == 0 && iface_methods.len != 0 {
		return false
	}
	symbol_fields := psi.fields_list(symbol_type)
	if symbol_fields.len == 0 && iface_fields.len != 0 {
		return false
	}

	return is_implemented(iface_methods, iface_fields, symbol_methods, symbol_fields)
}

fn candidates_by_methods_and_fields(methods []psi.PsiElement, fields []psi.PsiElement) []psi.PsiNamedElement {
	by_methods := candidates_by_methods(methods)
	by_fields := candidates_by_fields(fields)
	mut result := []psi.PsiNamedElement{cap: by_methods.len + by_fields.len}
	result << by_methods
	result << by_fields
	return result
}

fn candidates_by_methods(methods []psi.PsiElement) []psi.PsiNamedElement {
	mut candidates := []psi.PsiNamedElement{cap: 5}

	for method in methods {
		if method is psi.InterfaceMethodDeclaration {
			fingerprint := method.fingerprint()

			// all methods with the same fingerprint can probably be part of struct that implements the interface
			struct_methods := stubs_index.get_elements_from_by_name(.workspace, .methods_fingerprint,
				fingerprint)

			for struct_method in struct_methods {
				if struct_method is psi.FunctionOrMethodDeclaration {
					owner := struct_method.owner() or { continue }
					if owner is psi.PsiNamedElement {
						candidates << owner
					}
				}
			}
		}
	}

	return candidates
}

fn candidates_by_fields(fields []psi.PsiElement) []psi.PsiNamedElement {
	mut candidates := []psi.PsiNamedElement{cap: 5}

	for field in fields {
		if field is psi.FieldDeclaration {
			fingerprint := field.name()

			// all fields with the same fingerprint can probably be part of struct that implements the interface
			struct_fields := stubs_index.get_elements_from_by_name(.workspace, .fields_fingerprint,
				fingerprint)

			for struct_field in struct_fields {
				if struct_field is psi.FieldDeclaration {
					owner := struct_field.owner() or { continue }
					if owner is psi.PsiNamedElement {
						candidates << owner
					}
				}
			}
		}
	}

	return candidates
}
