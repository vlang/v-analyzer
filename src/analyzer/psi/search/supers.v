module search

import analyzer.psi

// supers returns all interfaces that are implemented by the given struct
//
// Search algorithm:
// 1. Find all methods and fields of the struct
// 2. Search for all interface methods and fields that have the same fingerprint
//    (see description in `search.implementations()`)
// 3. For each candidate, check that struct implements all methods and fields of the interface.
pub fn supers(strukt psi.StructDeclaration) []psi.PsiElement {
	struct_type := strukt.get_type()
	methods := psi.methods_list(struct_type)
	fields := strukt.fields()

	if methods.len == 0 && fields.len == 0 {
		return []
	}

	candidates := super_candidates_by_methods_and_fields(methods, fields)
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

		if candidate is psi.InterfaceDeclaration {
			if is_implemented_interface(methods, fields, *candidate) {
				result[name] = candidate
			}
		}
	}

	return result.values()
}

fn is_implemented_interface(symbol_methods []psi.PsiElement, symbol_fields []psi.PsiElement, iface psi.InterfaceDeclaration) bool {
	iface_methods := iface.methods()
	iface_fields := iface.fields()
	return is_implemented(iface_methods, iface_fields, symbol_methods, symbol_fields)
}

fn super_candidates_by_methods_and_fields(methods []psi.PsiElement, fields []psi.PsiElement) []psi.PsiNamedElement {
	by_methods := super_candidates_by_methods(methods)
	by_fields := super_candidates_by_fields(fields)
	mut result := []psi.PsiNamedElement{cap: by_methods.len + by_fields.len}
	result << by_methods
	result << by_fields
	return result
}

fn super_candidates_by_methods(methods []psi.PsiElement) []psi.PsiNamedElement {
	mut candidates := []psi.PsiNamedElement{cap: 5}

	for method in methods {
		if method is psi.FunctionOrMethodDeclaration {
			fingerprint := method.fingerprint()

			// all methods with the same fingerprint can probably be part of the same interface
			interface_methods := stubs_index.get_elements_from_by_name(.workspace, .interface_methods_fingerprint,
				fingerprint)

			for interface_method in interface_methods {
				if interface_method is psi.InterfaceMethodDeclaration {
					candidates << interface_method.owner() or { continue }
				}
			}
		}
	}

	return candidates
}

fn super_candidates_by_fields(fields []psi.PsiElement) []psi.PsiNamedElement {
	mut candidates := []psi.PsiNamedElement{cap: 5}

	for field in fields {
		if field is psi.FieldDeclaration {
			fingerprint := field.name()

			// all fields with the same fingerprint can probably be part of interface that can be implemented by the struct
			interface_fields := stubs_index.get_elements_from_by_name(.workspace, .interface_fields_fingerprint,
				fingerprint)

			for interface_field in interface_fields {
				if interface_field is psi.FieldDeclaration {
					owner := interface_field.owner() or { continue }
					if owner is psi.PsiNamedElement {
						candidates << owner
					}
				}
			}
		}
	}

	return candidates
}
