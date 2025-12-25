module psi

import analyzer.psi.types
import utils

pub struct ReferenceImpl {
	element        ReferenceExpressionBase
	file           ?&PsiFile
	for_types      bool
	for_attributes bool
}

pub fn new_reference(file ?&PsiFile, element ReferenceExpressionBase, for_types bool) &ReferenceImpl {
	return &ReferenceImpl{
		element:   element
		file:      file
		for_types: for_types
	}
}

pub fn new_attribute_reference(file ?&PsiFile, element ReferenceExpressionBase) &ReferenceImpl {
	return &ReferenceImpl{
		element:        element
		file:           file
		for_attributes: true
	}
}

fn (r &ReferenceImpl) element() PsiElement {
	return r.element as PsiElement
}

pub fn (r &ReferenceImpl) resolve() ?PsiElement {
	file := r.file or { return none }

	sub := SubResolver{
		containing_file: file
		element:         r.element
		for_types:       r.for_types
		for_attributes:  r.for_attributes
	}
	mut processor := ResolveProcessor{
		containing_file: file
		ref:             r.element
		ref_name:        r.element.name()
	}

	if from_cache := resolve_cache.get(r.element()) {
		return from_cache
	}

	sub.process_resolve_variants(mut processor)
	if processor.result.len == 0 {
		return none
	}

	result := processor.result.first()
	resolve_cache.put(r.element(), result)
	return result
}

pub struct SubResolver {
pub:
	containing_file ?&PsiFile
	element         ReferenceExpressionBase
	for_types       bool
	for_attributes  bool
}

fn (r &SubResolver) element() PsiElement {
	return r.element as PsiElement
}

pub fn (r &SubResolver) process_resolve_variants(mut processor PsiScopeProcessor) bool {
	return if qualifier := r.element.qualifier() {
		r.process_qualifier_expression(qualifier, mut processor)
	} else {
		r.process_unqualified_resolve(mut processor)
	}
}

pub fn (r &SubResolver) process_qualifier_expression(qualifier PsiElement, mut processor PsiScopeProcessor) bool {
	if qualifier is PsiTypedElement {
		typ := infer_type(qualifier as PsiElement)
		if typ !is types.UnknownType {
			if !r.process_type(typ, mut processor) {
				return false
			}
		}
	}

	if qualifier is ReferenceExpressionBase {
		resolved := qualifier.resolve() or { return true }
		if resolved is ImportSpec {
			elements := stubs_index.get_all_declarations_from_module(resolved.qualified_name(),
				r.for_types)
			for element in elements {
				if !processor.execute(element) {
					return false
				}
			}
		}

		if resolved is ModuleClause {
			file := r.containing_file or { return true }
			module_name := stubs_index.get_module_qualified_name(file.path)
			current_module_elements := stubs_index.get_all_declarations_from_module(module_name,
				r.for_types)
			for elem in current_module_elements {
				if !processor.execute(elem) {
					return false
				}
			}
		}

		if resolved is StructDeclaration {
			methods := static_methods_list(resolved.get_type())
			if !r.process_elements(methods, mut processor) {
				return false
			}
		}
	}

	return true
}

pub fn (r &SubResolver) process_elements(elements []PsiElement, mut processor PsiScopeProcessor) bool {
	for element in elements {
		if !processor.execute(element) {
			return false
		}
	}
	return true
}

pub fn (r &SubResolver) process_type(typ types.Type, mut processor PsiScopeProcessor) bool {
	if typ is types.StructType {
		if struct_ := r.find_struct(stubs_index, typ.qualified_name()) {
			is_method_ref := if grand := r.element().parent_nth(2) {
				grand is CallExpression
			} else {
				false
			}

			// If it is a call, then most likely it is a method call, but it
			// could be a function call that is stored in a structure field.
			if is_method_ref {
				if !r.process_methods(typ, mut processor) {
					return false
				}
				if !r.process_elements(struct_.fields(), mut processor) {
					return false
				}
			} else {
				if !r.process_elements(struct_.fields(), mut processor) {
					return false
				}
				if !r.process_methods(typ, mut processor) {
					return false
				}
			}

			for def in struct_.embedded_definitions() {
				if !processor.execute(def) {
					return false
				}
			}
		}

		if !r.process_any_type(mut processor) {
			return false
		}

		return true
	}

	if typ is types.InterfaceType {
		if interface_ := r.find_interface(stubs_index, typ.qualified_name()) {
			if !r.process_methods(typ, mut processor) {
				return false
			}
			if !r.process_elements(interface_.fields(), mut processor) {
				return false
			}
			if !r.process_elements(interface_.methods(), mut processor) {
				return false
			}

			for def in interface_.embedded_definitions() {
				if !processor.execute(def) {
					return false
				}
			}
		}

		if !r.process_any_type(mut processor) {
			return false
		}

		return true
	}

	if typ is types.EnumType {
		enum_ := r.find_enum(stubs_index, typ.qualified_name()) or { return true }
		if !r.process_elements(enum_.fields(), mut processor) {
			return false
		}

		if !r.process_methods(typ, mut processor) {
			return false
		}

		if enum_.is_flag() {
			if !r.process_type(types.flag_enum_type, mut processor) {
				return false
			}
		}

		if !r.process_any_type(mut processor) {
			return false
		}

		return true
	}

	if typ is types.ArrayType {
		if !r.process_methods(typ, mut processor) {
			return false
		}

		if !r.process_type(types.builtin_array_type, mut processor) {
			return false
		}

		if !r.process_any_type(mut processor) {
			return false
		}

		return true
	}

	if typ is types.MapType {
		if !r.process_methods(typ, mut processor) {
			return false
		}

		if !r.process_type(types.builtin_map_type, mut processor) {
			return false
		}

		if !r.process_any_type(mut processor) {
			return false
		}

		return true
	}

	if typ is types.PointerType {
		if !r.process_type(typ.inner, mut processor) {
			return false
		}
		if !r.process_any_type(mut processor) {
			return false
		}
		return true
	}

	if typ is types.OptionType {
		if !r.process_type(typ.inner, mut processor) {
			return false
		}
		if !r.process_any_type(mut processor) {
			return false
		}
		return true
	}

	if typ is types.ResultType {
		if !r.process_type(typ.inner, mut processor) {
			return false
		}
		if !r.process_any_type(mut processor) {
			return false
		}
		return true
	}

	if typ is types.AliasType {
		if !r.process_methods(typ, mut processor) {
			return false
		}

		if !r.process_type(typ.inner, mut processor) {
			return false
		}

		if !r.process_any_type(mut processor) {
			return false
		}

		return true
	}

	if typ is types.GenericInstantiationType {
		if !r.process_type(typ.inner, mut processor) {
			return false
		}
		if !r.process_any_type(mut processor) {
			return false
		}
		return true
	}

	if !r.process_methods(typ, mut processor) {
		return false
	}

	if !r.process_any_type(mut processor) {
		return false
	}

	return true
}

pub fn (r &SubResolver) process_any_type(mut processor PsiScopeProcessor) bool {
	return r.process_methods(types.any_type, mut processor)
}

pub fn (r &SubResolver) process_methods(typ types.Type, mut processor PsiScopeProcessor) bool {
	return r.process_elements(methods_list(typ), mut processor)
}

pub fn (r &SubResolver) process_unqualified_resolve(mut processor PsiScopeProcessor) bool {
	if r.for_attributes {
		return r.resolve_attribute(mut processor)
	}

	if parent := r.element().parent() {
		if parent is FieldName {
			return r.process_type_initializer_field(mut processor)
		}

		if parent.element_type() == .enum_fetch {
			return r.process_enum_fetch(parent, mut processor)
		}
	}

	if !r.process_block(mut processor) {
		return false
	}
	if !r.process_imported_modules(mut processor) {
		return false
	}
	if !r.process_module_clause(mut processor) {
		return false
	}
	if !r.process_owner_generic_ts(mut processor) {
		return false
	}
	if !r.process_os_module(mut processor) {
		return false
	}

	builtin_elements := stubs_index.get_all_declarations_from_module('builtin', r.for_types)
	for element in builtin_elements {
		if !processor.execute(element) {
			return false
		}
	}

	if r.for_types {
		stubs_elements := stubs_index.get_all_declarations_from_module('stubs', r.for_types)
		for element in stubs_elements {
			if !processor.execute(element) {
				return false
			}
		}
	}

	module_name := if file := r.containing_file {
		stubs_index.get_module_qualified_name(file.path)
	} else {
		''
	}

	element := r.element()
	if element is PsiNamedElement {
		fqn := if module_name.len != 0 {
			module_name + '.' + element.name()
		} else {
			element.name()
		}

		if !r.for_types {
			if func := r.find_function(stubs_index, fqn) {
				if !processor.execute(func) {
					return false
				}
			}

			if constant := r.find_constant(stubs_index, fqn) {
				if !processor.execute(constant) {
					return false
				}
			}
		}

		if struct_ := r.find_struct(stubs_index, fqn) {
			if !processor.execute(struct_) {
				return false
			}
		}

		if interface_ := r.find_interface(stubs_index, fqn) {
			if !processor.execute(interface_) {
				return false
			}
		}

		if enum_ := r.find_enum(stubs_index, fqn) {
			if !processor.execute(enum_) {
				return false
			}
		}

		if alias := r.find_type_alias(stubs_index, fqn) {
			if !processor.execute(alias) {
				return false
			}
		}

		// global variable cannot have module name
		if global_variable := r.find_global_variable(stubs_index, element.name()) {
			if !processor.execute(global_variable) {
				return false
			}
		}
	}

	mod_decls := stubs_index.get_all_declarations_from_module(module_name, r.for_types)
	if !r.process_elements(mod_decls, mut processor) {
		return false
	}

	return true
}

pub fn (r &SubResolver) walk_up(element PsiElement, mut processor PsiScopeProcessor) bool {
	mut run := element
	mut last_parent := element
	for {
		if mut run is ForStatement {
			vars := run.var_definitions()
			for v in vars {
				if !processor.execute(v) {
					return false
				}
			}
		}

		if mut run is IfExpression {
			if def := run.var_definition() {
				if !processor.execute(def) {
					return false
				}
			}
		}

		if mut run is Block {
			if !run.process_declarations(mut processor, last_parent) {
				return false
			}

			if !r.process_parameters(run, mut processor) {
				return false
			}

			if !r.process_receiver(run, mut processor) {
				return false
			}
		}

		if mut run is SourceFile {
			if !run.process_declarations(mut processor, last_parent) {
				return false
			}
		}

		if mut run is GenericParametersOwner {
			if parameters := run.generic_parameters() {
				params := parameters.parameters()
				for param in params {
					if !processor.execute(param) {
						return false
					}
				}
			}
		}

		last_parent = run
		run = run.parent() or { break }
	}
	return true
}

pub fn (_ &SubResolver) process_parameters(b Block, mut processor PsiScopeProcessor) bool {
	parent := b.parent() or { return true }

	if parent is SignatureOwner {
		signature := parent.signature() or { return true }

		params := signature.parameters()
		for param in params {
			if !processor.execute(param) {
				return false
			}
		}
	}

	return true
}

pub fn (_ &SubResolver) process_receiver(b Block, mut processor PsiScopeProcessor) bool {
	parent := b.parent() or { return true }

	if parent is FunctionOrMethodDeclaration {
		receiver := parent.receiver() or { return true }
		if !processor.execute(receiver) {
			return false
		}
	}

	return true
}

pub fn (r &SubResolver) process_block(mut processor PsiScopeProcessor) bool {
	// if r.containing_file.is_stub_based() {
	// 	return true
	// }

	// mut delegate := ResolveProcessor{
	// 	...processor
	// }
	// if delegate.result.len == 0 {
	// 	return true
	// }
	//
	// for result in delegate.result {
	// 	processor.result << result
	// }

	return r.walk_up(r.element as PsiElement, mut processor)
}

pub fn (r &SubResolver) process_module_clause(mut processor PsiScopeProcessor) bool {
    file := r.containing_file or { return true }
	mod := file.module_clause() or { return true }
	return processor.execute(mod)
}

pub fn (r &SubResolver) process_imported_modules(mut processor PsiScopeProcessor) bool {
    file := r.containing_file or { return true }
	search_name := r.element().get_text()
	import_spec := file.resolve_import_spec(search_name) or { return true }

	if !processor.execute(import_spec) {
		return false
	}

	return true
}

pub fn (r &SubResolver) process_enum_fetch(parent PsiElement, mut processor PsiScopeProcessor) bool {
	context_type := TypeInferer{}.infer_context_type(parent)
	return r.process_type(context_type, mut processor)
}

pub fn (r &SubResolver) process_type_initializer_field(mut processor PsiScopeProcessor) bool {
	if init_expr := r.element().parent_of_type(.type_initializer) {
		if init_expr is PsiTypedElement {
			typ := types.unwrap_generic_instantiation_type(types.unwrap_pointer_type(infer_type(init_expr as PsiElement)))
			if typ is types.StructType {
				if !r.process_struct_type_fields(typ, mut processor) {
					return false
				}
			}
			if typ is types.ArrayType {
				if !r.process_struct_type_fields(types.array_init_type, mut processor) {
					return false
				}
			}
			if typ is types.ChannelType {
				if !r.process_struct_type_fields(types.chan_init_type, mut processor) {
					return false
				}
			}
		}
	}

	if call_expr := r.element().parent_of_type(.call_expression) {
		if call_expr is CallExpression {
			resolved := call_expr.resolve() or { return true }
			if resolved is SignatureOwner {
				signature := resolved.signature() or { return true }
				parameters := signature.parameters()
				if parameters.len == 0 {
					return true
				}

				last_parameter := parameters.last()
				param_type := infer_type(last_parameter)
				if param_type is types.StructType {
					if !r.process_struct_type_fields(param_type, mut processor) {
						return false
					}
				}
			}
		}
	}

	return true
}

pub fn (r &SubResolver) process_struct_type_fields(struct_type types.StructType, mut processor PsiScopeProcessor) bool {
	if struct_ := r.find_struct(stubs_index, struct_type.qualified_name()) {
		fields := struct_.fields()
		for field in fields {
			if !processor.execute(field) {
				return false
			}
		}
	}
	return true
}

pub fn (r &SubResolver) process_os_module(mut processor PsiScopeProcessor) bool {
	file := r.containing_file or { return true }

	if !file.is_shell_script() {
		return true
	}

	// In shell scripts OS module is imported implicitly, so we need to process it elements.
	os_elements := stubs_index.get_all_declarations_from_module('os', r.for_types)
	return r.process_elements(os_elements, mut processor)
}

pub fn (r &SubResolver) process_owner_generic_ts(mut processor PsiScopeProcessor) bool {
	element := r.element()
	if element.text_length() != 1 {
		// for now V only support single char generic parameters
		return true
	}

	method := element.parent_of_type(.function_declaration) or { return true }
	if method is FunctionOrMethodDeclaration {
		receiver := method.receiver() or { return true }

		if receiver.is_parent_of(element) {
			return true
		}

		receiver_type := types.unwrap_alias_type(types.unwrap_pointer_type(receiver.get_type()))
		if receiver_type is types.GenericInstantiationType {
			inner := receiver_type.inner
			inner_name := inner.qualified_name()
			elements := stubs_index.get_any_elements_by_name(inner_name)
			if elements.len == 0 {
				return true
			}

			for resolved in elements {
				if resolved is GenericParametersOwner {
					params := resolved.generic_parameters() or { continue }
					parameters := params.parameters()
					for param in parameters {
						if !processor.execute(param) {
							return false
						}
					}
				}
			}
		}
	}

	return true
}

pub fn (_ &SubResolver) find_function(stubs_index StubIndex, name string) ?&FunctionOrMethodDeclaration {
	found := stubs_index.get_elements_by_name(.functions, name)
	if found.len != 0 {
		first := found.first()
		if first is FunctionOrMethodDeclaration {
			return first
		}
	}
	return none
}

pub fn (_ &SubResolver) find_struct(stubs_index StubIndex, name string) ?&StructDeclaration {
	found := stubs_index.get_elements_by_name(.structs, name)
	if found.len != 0 {
		first := found.first()
		if first is StructDeclaration {
			return first
		}
	}
	return none
}

pub fn (_ &SubResolver) find_interface(stubs_index StubIndex, name string) ?&InterfaceDeclaration {
	found := stubs_index.get_elements_by_name(.interfaces, name)
	if found.len != 0 {
		first := found.first()
		if first is InterfaceDeclaration {
			return first
		}
	}
	return none
}

pub fn (_ &SubResolver) find_enum(stubs_index StubIndex, name string) ?&EnumDeclaration {
	found := stubs_index.get_elements_by_name(.enums, name)
	if found.len != 0 {
		first := found.first()
		if first is EnumDeclaration {
			return first
		}
	}
	return none
}

pub fn (_ &SubResolver) find_constant(stubs_index StubIndex, name string) ?&ConstantDefinition {
	found := stubs_index.get_elements_by_name(.constants, name)
	if found.len != 0 {
		first := found.first()
		if first is ConstantDefinition {
			return first
		}
	}
	return none
}

pub fn (_ &SubResolver) find_type_alias(stubs_index StubIndex, name string) ?&TypeAliasDeclaration {
	found := stubs_index.get_elements_by_name(.type_aliases, name)
	if found.len != 0 {
		first := found.first()
		if first is TypeAliasDeclaration {
			return first
		}
	}
	return none
}

pub fn (_ &SubResolver) find_global_variable(stubs_index StubIndex, name string) ?&GlobalVarDefinition {
	found := stubs_index.get_elements_by_name(.global_variables, name)
	if found.len != 0 {
		first := found.first()
		if first is GlobalVarDefinition {
			return first
		}
	}
	return none
}

pub fn (_ &SubResolver) find_attribute(stubs_index StubIndex, name string) ?&StructDeclaration {
	found := stubs_index.get_elements_by_name(.attributes, name)
	if found.len != 0 {
		first := found.first()
		if first is StructDeclaration {
			return first
		}
	}
	return none
}

pub fn (r &SubResolver) resolve_attribute(mut processor PsiScopeProcessor) bool {
	element := r.element()
	if element is PsiNamedElement {
		if attr := r.find_attribute(stubs_index, element.name()) {
			if !processor.execute(attr) {
				return false
			}
		}
	}

	return true
}

pub struct ResolveProcessor {
	containing_file &PsiFile
	ref             ReferenceExpressionBase
	ref_name        string
mut:
	result []PsiElement
}

fn (mut r ResolveProcessor) execute(element PsiElement) bool {
	if element.is_equal(r.ref as PsiElement) {
		r.result << element
		return false
	}
	if element is PsiNamedElement {
		mut name := element.name()
		if name.ends_with('Attribute') {
			name = utils.pascal_case_to_snake_case(name.trim_string_right('Attribute'))
		}
		if name == r.ref_name {
			r.result << element as PsiElement
			return false
		}
	}
	return true
}

pub fn find_element(fqn string) ?PsiElement {
	found := stubs_index.get_any_elements_by_name(fqn)
	if found.len != 0 {
		return found.first()
	}
	return none
}

pub fn find_interface(fqn string) ?&InterfaceDeclaration {
	found := stubs_index.get_elements_by_name(.interfaces, fqn)
	if found.len != 0 {
		first := found.first()
		if first is InterfaceDeclaration {
			return first
		}
	}
	return none
}

pub fn find_struct(fqn string) ?&StructDeclaration {
	found := stubs_index.get_elements_by_name(.structs, fqn)
	if found.len != 0 {
		first := found.first()
		if first is StructDeclaration {
			return first
		}
	}
	return none
}

pub fn find_alias(fqn string) ?&TypeAliasDeclaration {
	found := stubs_index.get_elements_by_name(.type_aliases, fqn)
	if found.len != 0 {
		first := found.first()
		if first is TypeAliasDeclaration {
			return first
		}
	}
	return none
}
