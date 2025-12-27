module psi

import utils
import tree_sitter_v.bindings

pub enum StubType as u8 {
	root
	function_declaration
	method_declaration
	static_method_declaration
	static_receiver
	receiver
	signature
	parameter_list
	parameter_declaration
	struct_declaration
	interface_declaration
	interface_method_declaration
	enum_declaration
	field_declaration
	struct_field_scope
	enum_field_definition
	constant_declaration
	type_alias_declaration
	attributes
	attribute
	attribute_expression
	value_attribute
	// types
	plain_type
	type_reference_expression
	qualified_type
	pointer_type
	wrong_pointer_type
	array_type
	fixed_array_type
	function_type
	generic_type
	map_type
	channel_type
	shared_type
	thread_type
	multi_return_type
	option_type
	result_type
	type_parameters
	//
	visibility_modifiers
	import_list
	import_declaration
	import_spec
	import_path
	import_name
	import_alias
	selective_import_list
	module_clause
	reference_expression
	generic_parameters
	generic_parameter
	global_variable
	embedded_definition
}

pub fn node_type_to_stub_type(typ bindings.NodeType) StubType {
	return match typ {
		.function_declaration { .function_declaration }
		.receiver { .receiver }
		.static_method_declaration { .static_method_declaration }
		.static_receiver { .static_receiver }
		.signature { .signature }
		.parameter_list { .parameter_list }
		.parameter_declaration { .parameter_declaration }
		.struct_declaration { .struct_declaration }
		.interface_declaration { .interface_declaration }
		.interface_method_definition { .interface_method_declaration }
		.struct_field_declaration { .field_declaration }
		.const_definition { .constant_declaration }
		.type_declaration { .type_alias_declaration }
		.enum_declaration { .enum_declaration }
		.enum_field_definition { .enum_field_definition }
		.struct_field_scope { .struct_field_scope }
		.attributes { .attributes }
		.attribute { .attribute }
		.attribute_expression { .attribute_expression }
		.value_attribute { .value_attribute }
		// types
		.plain_type { .plain_type }
		.type_reference_expression { .type_reference_expression }
		.qualified_type { .qualified_type }
		.pointer_type { .pointer_type }
		.wrong_pointer_type { .wrong_pointer_type }
		.array_type { .array_type }
		.fixed_array_type { .fixed_array_type }
		.function_type { .function_type }
		.generic_type { .generic_type }
		.map_type { .map_type }
		.channel_type { .channel_type }
		.shared_type { .shared_type }
		.thread_type { .thread_type }
		.multi_return_type { .multi_return_type }
		.option_type { .option_type }
		.result_type { .result_type }
		.type_parameters { .type_parameters }
		// types end
		.visibility_modifiers { .visibility_modifiers }
		.import_list { .import_list }
		.import_declaration { .import_declaration }
		.import_spec { .import_spec }
		.import_path { .import_path }
		.import_name { .import_name }
		.import_alias { .import_alias }
		.selective_import_list { .selective_import_list }
		.module_clause { .module_clause }
		.reference_expression { .reference_expression }
		.generic_parameters { .generic_parameters }
		.generic_parameter { .generic_parameter }
		.global_var_definition { .global_variable }
		.embedded_definition { .embedded_definition }
		else { .root }
	}
}

pub struct StubbedElementType {}

pub fn (_ &StubbedElementType) index_stub(stub &StubBase, mut sink IndexSink) {
	if stub.stub_list.path.ends_with('_test.v') {
		return
	}

	if stub.stub_type == .module_clause {
		sink.occurrence(.modules_fingerprint, stub.name())
		return
	}

	if stub.stub_type == .function_declaration {
		name := stub.name()
		if name.starts_with('test_') {
			return
		}

		sink.occurrence(.functions, name)
	}

	if stub.stub_type == .method_declaration {
		receiver := stub.receiver()
		sink.occurrence(.methods, receiver)
		sink.occurrence(.methods_fingerprint, stub.additional)
	}

	if stub.stub_type == .static_method_declaration {
		receiver := stub.receiver()
		sink.occurrence(.static_methods, receiver)
	}

	if stub.stub_type == .struct_declaration {
		name := stub.name()
		if name.ends_with('Attribute') {
			// convert DeprecatedAfter to deprecated_after
			clear_name := utils.pascal_case_to_snake_case(name.trim_string_right('Attribute'))
			sink.occurrence(.attributes, clear_name)
			return
		}

		sink.occurrence(.structs, name)
	}

	if stub.stub_type == .interface_declaration {
		sink.occurrence(.interfaces, stub.name())
	}

	if stub.stub_type == .interface_method_declaration {
		sink.occurrence(.interface_methods_fingerprint, stub.additional)
	}

	if stub.stub_type == .enum_declaration {
		sink.occurrence(.enums, stub.name())
	}

	if stub.stub_type == .constant_declaration {
		sink.occurrence(.constants, stub.name())
	}

	if stub.stub_type == .type_alias_declaration {
		sink.occurrence(.type_aliases, stub.name())
	}

	if stub.stub_type == .global_variable {
		sink.occurrence(.global_variables, stub.name())
	}

	if stub.stub_type == .field_declaration {
		if parent := stub.parent_stub() {
			if parent.stub_type() == .struct_declaration {
				sink.occurrence(.fields_fingerprint, stub.name)
			} else if parent.stub_type() == .interface_declaration {
				sink.occurrence(.interface_fields_fingerprint, stub.name)
			}
		}
	}
}

pub fn (_ &StubbedElementType) create_psi(stub &StubBase) ?PsiElement {
	stub_type := stub.stub_type
	base_psi := new_psi_node_from_stub(stub.id, stub.stub_list)

	if stub_type == .function_declaration || stub_type == .method_declaration {
		return FunctionOrMethodDeclaration{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .static_method_declaration {
		return StaticMethodDeclaration{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .static_receiver {
		return StaticReceiver{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .receiver {
		return Receiver{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .signature {
		return Signature{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .parameter_list {
		return ParameterList{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .parameter_declaration {
		return ParameterDeclaration{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .type_reference_expression {
		return TypeReferenceExpression{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .struct_declaration {
		return StructDeclaration{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .interface_declaration {
		return InterfaceDeclaration{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .interface_method_declaration {
		return InterfaceMethodDeclaration{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .enum_declaration {
		return EnumDeclaration{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .enum_field_definition {
		return EnumFieldDeclaration{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .field_declaration {
		return FieldDeclaration{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .struct_field_scope {
		return StructFieldScope{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .constant_declaration {
		return ConstantDefinition{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .type_alias_declaration {
		return TypeAliasDeclaration{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .attributes {
		return Attributes{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .attribute {
		return Attribute{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .attribute_expression {
		return AttributeExpression{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .value_attribute {
		return ValueAttribute{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .plain_type {
		return PlainType{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .qualified_type {
		return QualifiedType{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .visibility_modifiers {
		return VisibilityModifiers{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .import_list {
		return ImportList{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .import_declaration {
		return ImportDeclaration{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .import_spec {
		return ImportSpec{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .import_path {
		return ImportPath{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .import_alias {
		return ImportAlias{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .selective_import_list {
		return SelectiveImportList{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .module_clause {
		return ModuleClause{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .reference_expression {
		return ReferenceExpression{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .generic_parameters {
		return GenericParameters{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .generic_parameter {
		return GenericParameter{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .global_variable {
		return GlobalVarDefinition{
			PsiElementImpl: base_psi
		}
	}
	if stub_type == .embedded_definition {
		return EmbeddedDefinition{
			PsiElementImpl: base_psi
		}
	}
	return base_psi
}

pub fn (_ &StubbedElementType) get_receiver_type(psi PsiNamedElement) string {
	typ := if psi is FunctionOrMethodDeclaration {
		receiver := psi.receiver() or { return '' }
		receiver.type_element() or { return '' }
	} else if psi is StaticMethodDeclaration {
		receiver := psi.receiver() or { return '' }
		PsiElement(receiver.PsiElementImpl)
	} else {
		return ''
	}

	text := typ.get_text().trim_string_left('&')

	if text.contains('[') && !text.contains('map[') && !text.starts_with('[') {
		// Foo[T] -> Foo
		return text.all_before('[')
	}

	return text
}

pub fn (s &StubbedElementType) create_stub(psi PsiElement, parent_stub &StubBase, module_fqn string) ?&StubBase {
	if psi is FunctionOrMethodDeclaration {
		text_range := psi.text_range()
		identifier_text_range := psi.identifier_text_range()
		comment := psi.doc_comment()

		mut receiver_type := s.get_receiver_type(psi)
		if receiver_type != '' {
			if module_fqn != '' {
				receiver_type = module_fqn + '.' + receiver_type
			}
		}

		is_method := receiver_type != ''
		stub_type := if is_method {
			StubType.method_declaration
		} else {
			StubType.function_declaration
		}

		fingerprint := if is_method {
			psi.fingerprint()
		} else {
			''
		}

		return new_stub_base(parent_stub, stub_type, psi.name(), identifier_text_range,
			text_range,
			comment:    comment
			receiver:   receiver_type
			additional: fingerprint
		)
	}

	if psi is StaticMethodDeclaration {
		text_range := psi.text_range()
		identifier_text_range := psi.identifier_text_range()
		comment := psi.doc_comment()

		mut receiver_type := s.get_receiver_type(psi)
		if receiver_type != '' {
			if module_fqn != '' {
				receiver_type = module_fqn + '.' + receiver_type
			}
		}

		return new_stub_base(parent_stub, .static_method_declaration, psi.name(), identifier_text_range,
			text_range,
			comment:  comment
			receiver: receiver_type
		)
	}

	if psi is StructDeclaration {
		text_range := psi.text_range()
		identifier_text_range := psi.identifier_text_range()
		comment := psi.doc_comment()
		name := if psi.is_attribute() {
			psi.name() + 'Attribute'
		} else {
			psi.name()
		}
		return new_stub_base(parent_stub, .struct_declaration, name, identifier_text_range,
			text_range,
			comment: comment
		)
	}

	if psi is InterfaceDeclaration {
		return declaration_stub(*psi, parent_stub, .interface_declaration)
	}

	if psi is InterfaceMethodDeclaration {
		return declaration_stub(*psi, parent_stub, .interface_method_declaration,
			additional: psi.fingerprint()
		)
	}

	if psi is StaticReceiver {
		return declaration_stub(*psi, parent_stub, .static_receiver, include_text: true)
	}

	if psi is Receiver {
		return declaration_stub(*psi, parent_stub, .receiver, include_text: true)
	}

	if psi is Signature {
		return text_based_stub(*psi, parent_stub, .signature)
	}

	if psi is ParameterList {
		return text_based_stub(*psi, parent_stub, .parameter_list)
	}

	if psi is ParameterDeclaration {
		return declaration_stub(*psi, parent_stub, .parameter_declaration, include_text: true)
	}

	if psi is EnumDeclaration {
		return declaration_stub(*psi, parent_stub, .enum_declaration)
	}

	if psi is EnumFieldDeclaration {
		if expression := psi.last_child() {
			text := expression.get_text()
			return declaration_stub(*psi, parent_stub, .enum_field_definition, additional: text)
		}
		return declaration_stub(*psi, parent_stub, .enum_field_definition)
	}

	if psi is FieldDeclaration {
		return declaration_stub(*psi, parent_stub, .field_declaration)
	}

	if psi is ConstantDefinition {
		if expression := psi.last_child() {
			text := expression.get_text()
			return declaration_stub(*psi, parent_stub, .constant_declaration, additional: text)
		}
		return declaration_stub(*psi, parent_stub, .constant_declaration)
	}

	if psi is TypeAliasDeclaration {
		return declaration_stub(*psi, parent_stub, .type_alias_declaration)
	}

	if psi is StructFieldScope {
		return text_based_stub(*psi, parent_stub, .struct_field_scope)
	}

	if psi is Attributes {
		text_range := psi.text_range()
		return new_stub_base(parent_stub, .attributes, '', text_range, text_range)
	}

	if psi is Attribute {
		return text_based_stub(*psi, parent_stub, .attribute)
	}

	if psi is AttributeExpression {
		return text_based_stub(*psi, parent_stub, .attribute_expression)
	}

	if psi is ValueAttribute {
		return text_based_stub(*psi, parent_stub, .value_attribute)
	}

	if psi is VisibilityModifiers {
		return text_based_stub(*psi, parent_stub, .visibility_modifiers)
	}

	if psi is ModuleClause {
		return declaration_stub(*psi, parent_stub, .module_clause)
	}

	if node_is_type(psi) {
		stub_type := node_type_to_stub_type(psi.node().type_name)
		return text_based_stub(psi, parent_stub, stub_type)
	}

	if psi is ImportSpec {
		return declaration_stub(*psi, parent_stub, .import_spec, include_text: true)
	}

	if psi.node().type_name in [.import_list, .import_declaration, .import_path, .import_name,
		.import_alias] {
		stub_type := node_type_to_stub_type(psi.node().type_name)
		return text_based_stub(psi, parent_stub, stub_type,
			include_text: psi.node().type_name !in [
				.import_list,
				.import_declaration,
				.selective_import_list,
			]
		)
	}

	if psi is ReferenceExpression {
		return text_based_stub(*psi, parent_stub, .reference_expression)
	}

	if psi is GenericParameters {
		return text_based_stub(*psi, parent_stub, .generic_parameters)
	}

	if psi is GenericParameter {
		return declaration_stub(*psi, parent_stub, .generic_parameter)
	}

	if psi is GlobalVarDefinition {
		return declaration_stub(*psi, parent_stub, .global_variable)
	}

	if psi is EmbeddedDefinition {
		return declaration_stub(*psi, parent_stub, .embedded_definition)
	}

	return none
}

@[params]
struct StubParams {
pub:
	include_text bool
	additional   string
}

@[inline]
pub fn declaration_stub(psi PsiNamedElement, parent_stub &StubElement, stub_type StubType, params StubParams) ?&StubBase {
	text_range := (psi as PsiElement).text_range()
	identifier_text_range := psi.identifier_text_range()
	return new_stub_base(parent_stub, stub_type, psi.name(), identifier_text_range, text_range,
		comment:    if psi is PsiDocCommentOwner { psi.doc_comment() } else { '' }
		text:       if params.include_text { (psi as PsiElement).get_text() } else { '' }
		additional: params.additional
	)
}

@[params]
struct TestStubParams {
pub:
	include_text bool = true
}

@[inline]
pub fn text_based_stub(psi PsiElement, parent_stub &StubElement, stub_type StubType, params TestStubParams) ?&StubBase {
	text_range := psi.text_range()
	return new_stub_base(parent_stub, stub_type, '', text_range, text_range,
		text: if params.include_text { psi.get_text() } else { '' }
	)
}

@[inline]
pub fn node_is_type(psi PsiElement) bool {
	return psi.node().type_name in [
		.plain_type,
		.type_reference_expression,
		.qualified_type,
		.pointer_type,
		.wrong_pointer_type,
		.array_type,
		.fixed_array_type,
		.function_type,
		.generic_type,
		.map_type,
		.channel_type,
		.shared_type,
		.thread_type,
		.multi_return_type,
		.option_type,
		.result_type,
		.type_parameters,
	]
}
