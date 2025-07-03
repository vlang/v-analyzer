module psi

import analyzer.psi.types

pub fn infer_type(elem ?PsiElement) types.Type {
	return TypeInferer{}.infer_type(elem)
}

pub fn convert_type(plain_type ?PsiElement) types.Type {
	mut visited := map[string]types.Type{}
	return TypeInferer{}.convert_type(plain_type, mut visited)
}

pub struct TypeInferer {}

pub fn (t &TypeInferer) infer_type(elem ?PsiElement) types.Type {
	element := elem or { return types.unknown_type }

	if from_cache := type_cache.get(element) {
		return from_cache
	}

	typ := t.infer_type_impl(elem)
	type_cache.put(element, typ)
	return typ
}

pub fn (t &TypeInferer) infer_type_impl(elem ?PsiElement) types.Type {
	element := elem or { return types.unknown_type }

	mut visited := map[string]types.Type{}

	match element.node.type_name {
		.in_expression, .is_expression, .select_expression {
			return types.new_primitive_type('bool')
		}
		.inc_expression, .dec_expression {
			return t.infer_type(element.first_child())
		}
		.as_type_cast_expression {
			return t.infer_type(element.last_child())
		}
		.spawn_expression, .go_expression {
			return types.new_thread_type(t.infer_type(element.last_child()))
		}
		.parenthesized_expression {
			expr := element.find_child_by_name('expression') or { return types.unknown_type }
			return t.infer_type(expr)
		}
		.receive_expression {
			operand := element.find_child_by_name('operand') or { return types.unknown_type }
			return types.unwrap_channel_type(t.infer_type(operand))
		}
		else {}
	}

	match element {
		BinaryExpression {
			return t.infer_binary_expression_type(element)
		}
		UnaryExpression {
			return t.infer_unary_expression_type(element)
		}
		OrBlockExpression, ResultPropagationExpression, OptionPropagationExpression {
			expr := element.expression() or { return types.unknown_type }
			expr_type := t.infer_type(expr)
			return types.unwrap_result_or_option_type(expr_type)
		}
		IndexExpression {
			return t.infer_index_expression_type(element)
		}
		SliceExpression {
			return t.infer_slice_expression_type(element)
		}
		Range {
			return t.infer_range_type(element)
		}
		SelectorExpression {
			return t.infer_selector_expression_type(element)
		}
		ReferenceExpression {
			return t.infer_reference_expression_type(element)
		}
		TypeInitializer {
			return t.infer_type_initializer_type(element, mut visited)
		}
		UnsafeExpression {
			return t.infer_unsafe_expression_type(element)
		}
		IfExpression {
			return t.infer_if_expression_type(element)
		}
		CompileTimeIfExpression {
			return t.infer_compile_time_if_expression_type(element)
		}
		MatchExpression {
			return t.infer_match_expression_type(element)
		}
		ArrayCreation {
			return t.infer_array_creation_type(element)
		}
		MapInitExpression {
			return t.infer_map_init_expression_type(element)
		}
		CallExpression {
			return t.infer_call_expression_type(element, mut visited)
		}
		Literal {
			return t.infer_literal_type(element)
		}
		Signature {
			return t.process_signature(element)
		}
		VarDefinition {
			return t.infer_var_definition_type(element)
		}
		FieldDeclaration {
			return t.infer_from_plain_type(element)
		}
		Receiver {
			return t.infer_from_plain_type(element)
		}
		ParameterDeclaration {
			return t.infer_parameter_declaration_type(element)
		}
		Block {
			return t.infer_block_type(element)
		}
		FunctionLiteral, FunctionOrMethodDeclaration, StaticMethodDeclaration,
		InterfaceMethodDeclaration {
			signature := element.signature() or { return types.unknown_type }
			return t.process_signature(signature)
		}
		EnumDeclaration, EnumFieldDeclaration, ConstantDefinition {
			return element.get_type()
		}
		TypeReferenceExpression {
			return t.infer_type_reference_type(element, mut visited)
		}
		GlobalVarDefinition {
			return t.infer_global_var_definition_type(element, mut visited)
		}
		EmbeddedDefinition {
			return t.infer_embedded_definition_type(element, mut visited)
		}
		else {
			return types.unknown_type
		}
	}
}

pub fn (t &TypeInferer) infer_binary_expression_type(element BinaryExpression) types.Type {
	match element.operator() {
		'&&', '||', '==', '!=', '<', '<=', '>', '>=' {
			return types.new_primitive_type('bool')
		}
		'<<' {
			return types.new_primitive_type('int')
		}
		'>>', '>>>' {
			return types.new_primitive_type('int')
		}
		'+', '-', '|', '^', '&', '*', '/' {
			left := element.left() or { return types.unknown_type }
			if left.node.type_name != .literal {
				return t.infer_type(left)
			}
			right := element.right() or { return types.unknown_type }
			return t.infer_type(right)
		}
		else {
			return types.unknown_type
		}
	}
}

pub fn (t &TypeInferer) infer_unary_expression_type(element UnaryExpression) types.Type {
	operator := element.operator()
	if operator == '!' {
		return types.new_primitive_type('bool')
	}

	expression := element.expression() or { return types.unknown_type }
	expr_type := t.infer_type(expression)

	return match operator {
		'&' { types.Type(types.new_pointer_type(expr_type)) }
		'*' { types.unwrap_pointer_type(expr_type) }
		'<-' { types.unwrap_channel_type(expr_type) }
		else { expr_type }
	}
}

pub fn (t &TypeInferer) infer_index_expression_type(element IndexExpression) types.Type {
	expr := element.expression() or { return types.unknown_type }
	expr_type := t.infer_type(expr)
	return t.infer_index_type(expr_type)
}

pub fn (t &TypeInferer) infer_slice_expression_type(element SliceExpression) types.Type {
	expr := element.expression() or { return types.unknown_type }
	expr_type := t.infer_type(expr)
	if expr_type is types.FixedArrayType {
		// [3]int -> []int
		return types.new_array_type(expr_type.inner)
	}
	return expr_type
}

pub fn (t &TypeInferer) infer_compile_time_if_expression_type(element CompileTimeIfExpression) types.Type {
	block := element.block()
	block_type := t.infer_type(block)
	if block_type is types.UnknownType {
		else_branch := element.else_branch() or { return types.unknown_type }
		return t.infer_type(else_branch)
	}
	return block_type
}

pub fn (t &TypeInferer) infer_match_expression_type(element MatchExpression) types.Type {
	arms := element.arms()
	if arms.len == 0 {
		return types.unknown_type
	}
	first := arms.first()
	block := first.find_child_by_name('block') or { return types.unknown_type }
	return t.infer_type(block)
}

pub fn (t &TypeInferer) infer_array_creation_type(element ArrayCreation) types.Type {
	expressions := element.expressions()
	if expressions.len == 0 {
		return types.new_array_type(types.unknown_type)
	}
	first_expr := expressions.first()

	if element.is_fixed {
		return types.new_fixed_array_type(t.infer_type(first_expr), expressions.len)
	}

	return types.new_array_type(t.infer_type(first_expr))
}

pub fn (t &TypeInferer) infer_map_init_expression_type(element MapInitExpression) types.Type {
	module_fqn := element.containing_file.module_fqn()
	key_values := element.key_values()
	if key_values.len == 0 {
		return types.new_map_type(module_fqn, types.unknown_type, types.unknown_type)
	}

	first_key_value := key_values.first()
	if first_key_value is MapKeyedElement {
		key := first_key_value.key() or { return types.unknown_type }
		value := first_key_value.value() or { return types.unknown_type }
		key_type := t.infer_type(key)
		value_type := t.infer_type(value)
		return types.new_map_type(module_fqn, key_type, value_type)
	}

	return types.new_map_type(module_fqn, types.unknown_type, types.unknown_type)
}

pub fn (t &TypeInferer) infer_call_expression_type(element CallExpression, mut visited map[string]types.Type) types.Type {
	if grand := element.expression() {
		if grand is FunctionLiteral {
			signature := grand.signature() or { return types.unknown_type }
			return t.convert_type(signature.result(), mut visited)
		}
	}
	return t.infer_call_expr_type(element)
}

pub fn (t &TypeInferer) infer_var_definition_type(element VarDefinition) types.Type {
	grand := element.parent_nth(2) or { return types.unknown_type }
	if grand.node.type_name == .range_clause {
		return t.process_range_clause(element, grand)
	}

	decl := element.declaration() or { return types.unknown_type }
	if init := decl.initializer_of(element) {
		typ := t.infer_type(init)
		if decl_parent := decl.parent() {
			if decl_parent is IfExpression {
				return types.unwrap_result_or_option_type(typ)
			}
		}

		if typ is types.MultiReturnType {
			parent := element.parent() or { return types.unknown_type }

			mut define_index := 0
			for index, def in parent.find_children_by_type(.reference_expression) {
				if def.is_equal(element) {
					define_index = index
					break
				}
			}

			inner_types := typ.types
			return inner_types[define_index] or { return types.unknown_type }
		}

		return typ
	}
	return types.unknown_type
}

pub fn (t &TypeInferer) infer_parameter_declaration_type(element ParameterDeclaration) types.Type {
	type_ := t.infer_from_plain_type(element)
	if _ := element.find_child_by_name('variadic') {
		return types.new_array_type(type_)
	}
	return type_
}

pub fn (t &TypeInferer) infer_block_type(element Block) types.Type {
	last_expression := element.last_expression() or { return types.unknown_type }
	return t.infer_type(last_expression)
}

pub fn (t &TypeInferer) infer_global_var_definition_type(element GlobalVarDefinition, mut visited map[string]types.Type) types.Type {
	type_element := element.find_child_by_type_or_stub(.plain_type) or { return types.unknown_type }
	return t.convert_type(type_element, mut visited)
}

pub fn (t &TypeInferer) infer_embedded_definition_type(element EmbeddedDefinition, mut visited map[string]types.Type) types.Type {
	if qualified_type := element.find_child_by_type_or_stub(.qualified_type) {
		return t.convert_type_inner(qualified_type, mut visited)
	}
	if generic_type := element.find_child_by_type_or_stub(.generic_type) {
		return t.convert_type_inner(generic_type, mut visited)
	}
	if ref_expression := element.find_child_by_type_or_stub(.type_reference_expression) {
		if ref_expression is TypeReferenceExpression {
			return t.infer_type_reference_type(ref_expression, mut visited)
		}
	}
	return types.unknown_type
}

pub fn (t &TypeInferer) infer_reference_expression_type(element ReferenceExpression) types.Type {
	if element.text_matches('it') {
		call := get_it_call(element) or { return types.unknown_type }
		caller_type := call.caller_type()
		if caller_type is types.ArrayType {
			return caller_type.inner
		}
		return types.unknown_type
	}

	resolved := element.resolve() or { return types.unknown_type }
	return t.infer_type(resolved)
}

pub fn (t &TypeInferer) infer_if_expression_type(element IfExpression) types.Type {
	block := element.block()
	block_type := t.infer_type(block)
	if block_type is types.UnknownType {
		else_branch := element.else_branch() or { return types.unknown_type }
		return t.infer_type(else_branch)
	}
	return block_type
}

pub fn (t &TypeInferer) infer_unsafe_expression_type(element UnsafeExpression) types.Type {
	block := element.block()
	return t.infer_type(block)
}

pub fn (t &TypeInferer) infer_type_initializer_type(element TypeInitializer, mut visited map[string]types.Type) types.Type {
	type_element := element.find_child_by_type(.plain_type) or { return types.unknown_type }
	return t.convert_type(type_element, mut visited)
}

pub fn (t &TypeInferer) infer_selector_expression_type(element SelectorExpression) types.Type {
	resolved := element.resolve() or { return types.unknown_type }
	typ := t.infer_type(resolved)
	if types.is_generic(typ) {
		return GenericTypeInferer{}.infer_generic_fetch(resolved, element, typ)
	}
	return typ
}

pub fn (t &TypeInferer) infer_range_type(element Range) types.Type {
	if element.inclusive() {
		left := element.left() or { return types.unknown_type }
		return t.infer_type(left)
	}
	return types.new_array_type(types.new_primitive_type('int'))
}

pub fn (t &TypeInferer) process_signature(signature Signature) types.Type {
	params := signature.parameters()
	param_types := params.map(fn (it PsiElement) types.Type {
		// TODO: support fn (int, string) without names
		if it is PsiTypedElement {
			return it.get_type()
		}
		return types.unknown_type
	})
	result := signature.result()
	mut visited := map[string]types.Type{}
	result_type := t.convert_type(result, mut visited)
	return types.new_function_type(signature.containing_file.module_fqn(), param_types,
		result_type, result == none)
}

pub fn (t &TypeInferer) process_range_clause(element PsiElement, range PsiElement) types.Type {
	right := range.find_child_by_name('right') or { return types.unknown_type }
	right_type := types.unwrap_alias_type(t.infer_type(right))
	var_definition_list := range.find_child_by_name('left') or { return types.unknown_type }
	var_definitions := var_definition_list.find_children_by_type(.var_definition)

	if var_definitions.len == 1 {
		if right_type is types.ArrayType {
			return right_type.inner
		}
		if right_type is types.FixedArrayType {
			return right_type.inner
		}
		if right_type is types.MapType {
			return right_type.value
		}
		if right_type is types.StructType {
			if right_type.name() == 'string' {
				return types.new_primitive_type('u8')
			}

			return t.infer_iterator_struct(right_type)
		}
	}

	mut define_index := 0
	for index, def in var_definitions {
		if def.is_equal(element) {
			define_index = index
			break
		}
	}

	if define_index == 0 {
		if right_type is types.MapType {
			return right_type.key
		}
		return types.new_primitive_type('int')
	}

	if define_index == 1 {
		if right_type is types.ArrayType {
			return right_type.inner
		}
		if right_type is types.FixedArrayType {
			return right_type.inner
		}
		if right_type is types.MapType {
			return right_type.value
		}
		if right_type is types.StructType {
			if right_type.name() == 'string' {
				return types.new_primitive_type('u8')
			}

			return t.infer_iterator_struct(right_type)
		}

		return types.unknown_type
	}

	return types.unknown_type
}

pub fn (_ &TypeInferer) infer_iterator_struct(typ types.Type) types.Type {
	method := find_method(typ, 'next') or { return types.unknown_type }
	if method is FunctionOrMethodDeclaration {
		signature := method.signature() or { return types.unknown_type }
		func_type := signature.get_type()
		if func_type is types.FunctionType {
			return types.unwrap_result_or_option_type(func_type.result)
		}
	}

	return types.unknown_type
}

pub fn (t &TypeInferer) infer_call_expr_type(element CallExpression) types.Type {
	if element.is_json_decode() {
		return types.new_result_type(element.get_json_decode_type(), false)
	}

	if resolved := element.resolve() {
		expr_type := t.infer_type(resolved)
		if expr_type is types.FunctionType {
			result_type := expr_type.result
			if types.is_generic(result_type) {
				if resolved is GenericParametersOwner {
					return GenericTypeInferer{}.infer_generic_call(element, resolved,
						result_type)
				}
			}

			if resolved is FunctionOrMethodDeclaration {
				if !resolved.is_method() {
					return result_type
				}

				if typ := t.process_map_array_method_call(resolved, expr_type, element) {
					return typ
				}
			}

			return result_type
		}
	}

	// most probably type cast expression: PsiElement(node)
	// try to resolve as type
	expr := element.ref_expression() or { return types.unknown_type }
	ref := new_reference(element.containing_file, expr, true)
	if resolved := ref.resolve() {
		if resolved is PsiTypedElement {
			return resolved.get_type()
		}
	}

	return types.unknown_type
}

pub fn (t &TypeInferer) process_map_array_method_call(element FunctionOrMethodDeclaration, element_type types.FunctionType,
	expr CallExpression) ?types.Type {
	receiver_type := types.unwrap_pointer_type(element.receiver_type())

	if types.is_builtin_array_type(receiver_type) {
		if typ := t.process_array_method_call(element, element_type, expr) {
			return typ
		}
	}

	if types.is_builtin_map_type(receiver_type) {
		if typ := t.process_map_method_call(element, expr) {
			return typ
		}
	}

	return none
}

pub fn (_ &TypeInferer) process_array_method_call(element FunctionOrMethodDeclaration, element_type types.FunctionType,
	expr CallExpression) ?types.Type {
	return_type := element_type.result

	if return_type is types.VoidPtrType {
		caller_type := expr.caller_type()
		if caller_type is types.ArrayType {
			return caller_type.inner
		}
	}

	if types.is_builtin_array_type(return_type) {
		if element.name() == 'map' {
			arguments := expr.arguments()
			first_arg := arguments[0] or { return none }
			first_arg_type := infer_type(first_arg)

			// map(fn (int) <type> { ... }) -> array<type>
			if first_arg_type is types.FunctionType {
				return *types.new_array_type(first_arg_type.result)
			}

			// map(it > 10) -> array<bool>
			return *types.new_array_type(first_arg_type)
		}

		return expr.caller_type()
	}

	return none
}

pub fn (_ &TypeInferer) process_map_method_call(element FunctionOrMethodDeclaration, expr CallExpression) ?types.Type {
	caller_type := types.unwrap_alias_type(expr.caller_type())

	if caller_type is types.MapType {
		match element.name() {
			'keys' { return *types.new_array_type(caller_type.key) }
			'values' { return *types.new_array_type(caller_type.value) }
			'clone', 'move' { return caller_type }
			else { return none }
		}
	}

	return none
}

pub fn (_ &TypeInferer) infer_literal_type(element Literal) types.Type {
	child := element.first_child() or { return types.unknown_type }
	if child.node.type_name == .interpreted_string_literal
		|| child.node.type_name == .raw_string_literal {
		return types.string_type
	}

	if child.node.type_name == .c_string_literal {
		return types.new_pointer_type(types.new_primitive_type('u8'))
	}

	if child.node.type_name == .int_literal {
		return types.new_primitive_type('int')
	}

	if child.node.type_name == .float_literal {
		return types.new_primitive_type('f64')
	}

	if child.node.type_name == .rune_literal {
		return types.new_primitive_type('rune')
	}

	if child.node.type_name == .true_ || child.node.type_name == .false_ {
		return types.new_primitive_type('bool')
	}

	if child.node.type_name == .nil_ {
		return types.new_primitive_type('voidptr')
	}

	if child.node.type_name == .none_ {
		return types.new_primitive_type('none')
	}

	return types.unknown_type
}

pub fn (t &TypeInferer) infer_index_type(typ types.Type) types.Type {
	if typ is types.ArrayType {
		return typ.inner
	}
	if typ is types.FixedArrayType {
		return typ.inner
	}
	if typ is types.MapType {
		return typ.value
	}
	if typ is types.StructType {
		if typ.name == 'string' {
			return types.new_primitive_type('u8')
		}

		return types.unknown_type
	}
	if typ is types.PointerType {
		return typ.inner
	}

	return types.unknown_type
}

pub fn (t &TypeInferer) convert_type(plain_type ?PsiElement, mut visited map[string]types.Type) types.Type {
	typ := plain_type or { return types.unknown_type }
	if typ !is PlainType {
		return types.unknown_type
	}

	type_text := typ.get_text()

	if type_text in visited {
		return visited[type_text]
	}

	mut child := typ.first_child_or_stub() or { return types.unknown_type }
	for child.element_type() == .unknown {
		child = child.next_sibling_or_stub() or { return types.unknown_type }
	}

	type_inner := t.convert_type_inner(child, mut visited)
	visited[type_text] = type_inner
	return type_inner
}

pub fn (t &TypeInferer) convert_type_inner(element PsiElement, mut visited map[string]types.Type) types.Type {
	if element.element_type() == .pointer_type {
		inner := element.last_child_or_stub()
		return types.new_pointer_type(t.convert_type(inner, mut visited))
	}

	if element.element_type() == .array_type {
		inner := element.last_child_or_stub()
		return types.new_array_type(t.convert_type(inner, mut visited))
	}

	if element.element_type() == .fixed_array_type {
		// TODO: parse size
		inner := element.last_child_or_stub()
		return types.new_array_type(t.convert_type(inner, mut visited))
	}

	if element.element_type() == .thread_type {
		inner := element.last_child_or_stub()
		return types.new_thread_type(t.convert_type(inner, mut visited))
	}

	if element.element_type() == .channel_type {
		inner := element.last_child_or_stub()
		return types.new_channel_type(t.convert_type(inner, mut visited))
	}

	if element.element_type() == .option_type {
		inner := element.last_child_or_stub()
		return types.new_option_type(t.convert_type(inner, mut visited), inner == none)
	}

	if element.element_type() == .result_type {
		inner := element.last_child_or_stub()
		return types.new_result_type(t.convert_type(inner, mut visited), inner == none)
	}

	if element.element_type() == .multi_return_type {
		inner_type_elements := element.find_children_by_type_or_stub(.plain_type)
		inner_types := inner_type_elements.map(t.convert_type(it, mut visited))
		return types.new_multi_return_type(inner_types)
	}

	if element.element_type() == .map_type {
		module_fqn := element.containing_file.module_fqn()
		types_inner := element.find_children_by_type_or_stub(.plain_type)
		if types_inner.len != 2 {
			return types.new_map_type(module_fqn, types.unknown_type, types.unknown_type)
		}

		key := types_inner[0]
		value := types_inner[1]
		return types.new_map_type(module_fqn, t.convert_type(key, mut visited), t.convert_type(value, mut
			visited))
	}

	if element.element_type() == .function_type {
		signature := element.find_child_by_type_or_stub(.signature) or { return types.unknown_type }
		if signature is Signature {
			return t.process_signature(signature)
		}

		return types.unknown_type
	}

	if element.element_type() == .generic_type {
		inner_type := if inner := element.find_child_by_type_or_stub(.type_reference_expression) {
			if inner is TypeReferenceExpression {
				t.infer_type_reference_type(inner, mut visited)
			} else {
				return types.unknown_type
			}
		} else if inner_qualified := element.find_child_by_type_or_stub(.qualified_type) {
			t.convert_type_inner(inner_qualified, mut visited)
		} else {
			return types.unknown_type
		}

		type_parameters := element.find_child_by_type_or_stub(.type_parameters) or {
			return inner_type
		}
		type_parameters_list := type_parameters.find_children_by_type_or_stub(.plain_type)

		return types.new_generic_instantiation_type(inner_type, type_parameters_list.map(t.convert_type(it, mut
			visited)))
	}

	if element is QualifiedType {
		if ref := element.right() {
			if ref is TypeReferenceExpression {
				return t.infer_type_reference_type(ref, mut visited)
			}
		}
	}

	if element is TypeReferenceExpression {
		return t.infer_type_reference_type(element, mut visited)
	}

	return types.unknown_type
}

fn (t &TypeInferer) infer_type_reference_type(element TypeReferenceExpression, mut visited map[string]types.Type) types.Type {
	text := element.get_text()
	if types.is_primitive_type(text) {
		// fast path
		return types.new_primitive_type(text)
	}

	if text == 'string' {
		return types.string_type
	}

	if text == 'voidptr' {
		return types.voidptr_type
	}

	if text == 'array' {
		return types.builtin_array_type
	}

	if text == 'map' {
		return types.builtin_map_type
	}

	resolved := element.resolve() or { return types.unknown_type }
	if resolved is StructDeclaration {
		return resolved.get_type()
	}

	if resolved is InterfaceDeclaration {
		return resolved.get_type()
	}

	if resolved is EnumDeclaration {
		return resolved.get_type()
	}

	if resolved is TypeAliasDeclaration {
		name := resolved.name()
		visited[name] = types.unknown_type
		types_list := resolved.types()
		if types_list.len == 0 {
			return types.unknown_type
		}
		first := types_list.first()
		alias_type := types.new_alias_type(name, resolved.module_name(), t.convert_type(first, mut
			visited))
		visited[name] = alias_type
		return alias_type
	}

	if resolved is GenericParameter {
		return types.new_generic_type(element.name())
	}

	return types.unknown_type
}

fn (t &TypeInferer) infer_from_plain_type(element PsiElement) types.Type {
	plain_typ := element.find_child_by_type_or_stub(.plain_type) or { return types.unknown_type }
	mut visited := map[string]types.Type{}
	return t.convert_type(plain_typ, mut visited)
}

pub fn (t &TypeInferer) infer_context_type(elem ?PsiElement) types.Type {
	element := elem or { return types.unknown_type }
	parent := element.parent() or { return types.unknown_type }

	if parent.element_type() == .binary_expression {
		right := parent.last_child_or_stub() or { return types.unknown_type }
		if right.is_equal(element) {
			left := parent.first_child_or_stub() or { return types.unknown_type }
			return t.infer_type(left)
		}
	}

	if parent.element_type() == .expression_list {
		grand := parent.parent() or { return types.unknown_type }
		if grand.element_type() == .assignment_statement {
			// TODO: support multiple assignments
			right_list := grand.last_child_or_stub() or { return types.unknown_type }
			right := right_list.first_child_or_stub() or { return types.unknown_type }
			if right.is_equal(element) {
				left_list := grand.first_child_or_stub() or { return types.unknown_type }
				left := left_list.first_child_or_stub() or { return types.unknown_type }
				return t.infer_type(left)
			}
		}
	}

	if parent.element_type() == .match_expression_list {
		match_expr := parent.parent_of_type(.match_expression) or { return types.unknown_type }
		if match_expr is MatchExpression {
			return t.infer_type(match_expr.expression())
		}
	}

	if parent is KeyedElement {
		field := parent.field() or { return types.unknown_type }
		ref := field.reference_expression() or { return types.unknown_type }
		resolved := ref.resolve() or { return types.unknown_type }
		return t.infer_from_plain_type(resolved)
	}

	if parent.element_type() == .argument {
		call_expression := parent.parent_nth(2) or { return types.unknown_type }
		if call_expression is CallExpression {
			called := call_expression.resolve() or { return types.unknown_type }

			if called is FunctionOrMethodDeclaration {
				if called.is_method()
					&& called.receiver_type().qualified_name() == types.flag_enum_type.qualified_name() {
					// when color.has(.red)
					return call_expression.caller_type()
				}
			}

			typ := t.infer_type(called)

			if typ is types.FunctionType {
				index := call_expression.parameter_index_on_offset(parent.node.start_byte())
				param_type := typ.params[index] or { return types.unknown_type }
				return param_type
			}
		}
	}

	if parent.element_type() == .expression_list {
		grand := parent.parent() or { return types.unknown_type }
		if grand.element_type() == .return_statement {
			return t.enclosing_function_return_type(grand)
		}
	}

	if parent.element_type() == .simple_statement {
		if_expr := parent.parent_nth(2) or { return types.unknown_type }
		if if_expr is IfExpression {
			return_stmt := if_expr.parent_nth(2) or { return types.unknown_type }
			if return_stmt.element_type() == .return_statement {
				return t.enclosing_function_return_type(return_stmt)
			}
		}

		match_expr := if_expr.parent_nth(2) or { return types.unknown_type }
		if match_expr is MatchExpression {
			return_stmt := match_expr.parent_nth(2) or { return types.unknown_type }
			if return_stmt.element_type() == .return_statement {
				return t.enclosing_function_return_type(return_stmt)
			}
		}
	}

	if parent is FieldDeclaration {
		return parent.get_type()
	}

	if parent is ArrayCreation {
		expressions := parent.expressions()
		first := expressions[0] or { return types.unknown_type }

		if first.element_type() != .enum_fetch {
			return t.infer_type(first)
		}

		bin_expr := parent.parent() or { return types.unknown_type }
		if bin_expr.element_type() in [.binary_expression, .in_expression] {
			left := bin_expr.first_child_or_stub() or { return types.unknown_type }
			if left.is_parent_of(parent) {
				return types.unknown_type
			}

			return t.infer_type(left)
		}

		return types.unknown_type
	}

	return types.unknown_type
}

fn (_ &TypeInferer) enclosing_function_return_type(elem PsiElement) types.Type {
	function := elem.parent_of_any_type(.function_declaration, .function_literal) or {
		return types.unknown_type
	}
	if function is SignatureOwner {
		signature := function.signature() or { return types.unknown_type }
		typ := signature.get_type()
		if typ is types.FunctionType {
			return typ.result
		}
	}
	return types.unknown_type
}
