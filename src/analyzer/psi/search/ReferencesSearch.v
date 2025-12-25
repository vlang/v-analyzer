module search

import analyzer.psi
import analyzer.parser
import runtime
import math
import time
import loglib

@[params]
pub struct SearchParams {
pub:
	// include_declaration indicates whether to include the declaration
	// of the symbol in the search results
	// This is useful when we want to find all usages of a symbol for
	// refactoring purposes, for example, rename a symbol.
	//
	// When include_declaration is true, results will include the declaration as `PsiNamedElement`,
	// not `Identifier`, so caller should take care of this.
	// For example, use `identifier_text_range()` instead of `text_range()` to get the range of the
	// identifier.
	include_declaration bool
	// only_in_current_file indicates whether to search only in the current file
	// This is set to true when we find references of a symbol for `documentHighlight`
	// request.
	only_in_current_file bool
}

pub fn references(element psi.PsiElement, params SearchParams) []psi.PsiElement {
	containing_file := element.containing_file() or { return [] }
	return ReferencesSearch{
		params:          params
		containing_file: containing_file
	}.search(element)
}

struct ReferencesSearch {
	params          SearchParams
	containing_file &psi.PsiFile
}

pub fn (r &ReferencesSearch) search(element psi.PsiElement) []psi.PsiElement {
	resolved := resolve_identifier(element) or { return [] }
	if resolved is psi.VarDefinition {
		// variables cannot be used outside the scope where they are defined
		scope := element.parent_of_any_type(.block, .source_file) or { return [] }
		return r.search_in_scope(resolved, scope)
	}
	if resolved is psi.ParameterDeclaration {
		parent := resolved.parent_of_any_type(.function_literal, .function_declaration) or {
			return []
		}
		return r.search_in_scope(resolved, parent)
	}
	if resolved is psi.Receiver {
		parent := resolved.parent_of_type(.function_declaration) or { return [] }
		return r.search_in_scope(resolved, parent)
	}
	if resolved is psi.ImportName {
		import_spec := resolved.parent_of_type(.import_spec) or { return [] }
		if import_spec is psi.ImportSpec {
			file := element.containing_file() or { return [] }
			return r.search_in_scope(import_spec, file.root())
		}
		return []
	}
	if resolved is psi.ModuleClause {
		return r.search_module_import(resolved)
	}
	if resolved is psi.GenericParameter {
		return r.search_generic_parameter(resolved)
	}
	if resolved is psi.FunctionOrMethodDeclaration {
		if resolved.is_method() {
			return r.search_method(resolved)
		}
	}
	if resolved is psi.PsiNamedElement {
		return r.search_named_element(resolved)
	}
	return []
}

// search_method searches references of a method.
//
// If the struct of the method implements some interface, we must also look for the use of the
// interface method, since the method of the struct for which we are looking for references is
// also implicitly called through it.
//
// This is important for renaming, because if we rename a struct method, we must also rename the
// interface method so that the struct continues to implement it.
pub fn (r &ReferencesSearch) search_method(element psi.FunctionOrMethodDeclaration) []psi.PsiElement {
	iface_super_methods := super_methods(element)
	if iface_super_methods.len == 0 {
		return r.search_named_element(element)
	}

	mut result := r.search_named_element(element)
	for super_method in iface_super_methods {
		if super_method is psi.PsiNamedElement {
			result << r.search_named_element(super_method)
		}
	}

	return result
}

pub fn (r &ReferencesSearch) search_generic_parameter(element psi.GenericParameter) []psi.PsiElement {
	return r.search_private_named_element(element)
}

pub fn (r &ReferencesSearch) search_module_import(element psi.PsiNamedElement) []psi.PsiElement {
	if r.params.only_in_current_file {
		// module cannot be imported in the same file where it is defined
		return []
	}

	mut result := []psi.PsiElement{cap: 10}
	psi_element := element as psi.PsiElement
	file := psi_element.containing_file() or { return [] }
	file_sink := file.index_sink() or { return [] }
	module_name := file_sink.module_fqn()
	depends_sinks := stubs_index.get_all_sink_depends_on(module_name)

	for sink in depends_sinks {
		root := sink.stub_list.index_map[0] or { continue }
		children := root.children_stubs()
		for child in children {
			if child.stub_type() == .import_list {
				declarations := child.children_stubs()
				for declaration in declarations {
					import_spec := declaration.first_child() or { continue }
					import_path := import_spec.first_child() or { continue }
					if import_path.stub_type() == .import_path {
						if import_path.text() == module_name {
							result << import_path.get_psi() or { continue }
						}
					}
				}
			}
		}
	}

	return result
}

pub fn (r &ReferencesSearch) search_named_element(element psi.PsiNamedElement) []psi.PsiElement {
	is_public := element.is_public()
	is_field := element is psi.FieldDeclaration
	if is_public || is_field {
		return r.search_public_named_element(element)
	} else {
		return r.search_private_named_element(element)
	}
}

pub fn (r &ReferencesSearch) search_private_named_element(element psi.PsiNamedElement) []psi.PsiElement {
	module_name := r.containing_file.module_fqn()
	return r.search_named_element_in_module(module_name, element)
}

pub fn (r &ReferencesSearch) search_named_element_in_module(module_name string, element psi.PsiNamedElement) []psi.PsiElement {
	mut result := []psi.PsiElement{cap: 10}
	if r.params.include_declaration {
		result << element as psi.PsiElement
	}

	if r.params.only_in_current_file {
		result << r.search_in(element, r.containing_file.root())
		return result
	}

	sinks_to_search := stubs_index.get_all_sinks_from_module(module_name)
	if sinks_to_search.len == 0 {
		return []
	}

	mut path_to_search := []string{cap: sinks_to_search.len}
	for sink in sinks_to_search {
		path_to_search << sink.stub_list.path
	}

	cpus := runtime.nr_cpus()
	workers := math.max(cpus - 2, 1)
	parsed_files := parser.parse_batch_files(path_to_search, workers)

	for parsed_file in parsed_files {
		psi_file := psi.new_psi_file(parsed_file.path, parsed_file.tree, parsed_file.source_text)
		result << r.search_in(element, psi_file.root)
	}

	return result
}

pub fn (r &ReferencesSearch) search_public_named_element(element psi.PsiNamedElement) []psi.PsiElement {
	if r.params.only_in_current_file {
		mut result := []psi.PsiElement{cap: 10}
		if r.params.include_declaration {
			result << element as psi.PsiElement
		}
		result << r.search_in(element, r.containing_file.root())
		return result
	}

	file_sink := r.containing_file.index_sink() or { return [] }
	module_name := file_sink.module_fqn()

	// we don't want to search symbol usages in the same module where it is defined
	// if this is not a workspace module
	usages_in_own_module := if file_sink.kind == .workspace {
		r.search_named_element_in_module(module_name, element)
	} else {
		[]psi.PsiElement{}
	}

	mut files := []string{cap: 10}
	depends_sinks := stubs_index.get_all_sink_depends_on(module_name)
	for sink in depends_sinks {
		if sink.kind != .workspace {
			continue
		}

		files << sink.stub_list.path
	}

	mut usages_in_depends_modules := []psi.PsiElement{cap: 10}
	cpus := runtime.nr_cpus()
	workers := math.max(cpus - 2, 1)

	watch := time.new_stopwatch(auto_start: true)
	parsed_files := parser.parse_batch_files(files, workers)
	for parsed_result in parsed_files {
		psi_file := psi.new_psi_file(parsed_result.path, parsed_result.tree, parsed_result.source_text)
		usages_in_depends_modules << r.search_in(element, psi_file.root)
	}

	loglib.with_duration(watch.elapsed()).info('Finish searching in depends modules')

	mut all_usages := []psi.PsiElement{cap: usages_in_own_module.len + usages_in_depends_modules.len}
	all_usages << usages_in_own_module
	all_usages << usages_in_depends_modules
	return all_usages
}

pub fn (r &ReferencesSearch) search_in_scope(element psi.PsiNamedElement, scope psi.PsiElement) []psi.PsiElement {
	mut result := []psi.PsiElement{cap: 10}
	if r.params.include_declaration {
		result << element as psi.PsiElement
	}

	// looking for all references to a variable inside the scope
	result << r.search_in(element, scope)

	return result
}

pub fn (r &ReferencesSearch) search_in(element psi.PsiNamedElement, search_root psi.PsiElement) []psi.PsiElement {
	name := element.name()
	mut result := []psi.PsiElement{cap: 10}
	for node in psi.new_psi_tree_walker(search_root) {
		if node is psi.ReferenceExpression || node is psi.TypeReferenceExpression {
			ref := node as psi.ReferenceExpressionBase
			if node.text_matches(name) {
				resolved := ref.resolve() or { continue }
				if resolved is psi.PsiNamedElement {
					if resolved.identifier_text_range() == element.identifier_text_range() {
						result << node
					}
				}
			}
		}
	}
	return result
}

fn resolve_identifier(element psi.PsiElement) ?psi.PsiElement {
	parent := element.parent()?
	resolved := if parent is psi.ReferenceExpression {
		parent.resolve()?
	} else if parent is psi.TypeReferenceExpression {
		parent.resolve()?
	} else {
		parent
	}

	return resolved
}
