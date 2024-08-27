module psi

import tree_sitter_v.bindings

pub type StubId = int

const non_stubbed_element = StubId(-1)

@[params]
pub struct StubData {
pub:
	text       string
	comment    string
	receiver   string
	additional string
}

@[heap]
pub struct StubBase {
	StubData
pub:
	name                  string
	identifier_text_range TextRange
	text_range            TextRange
	parent_id             StubId
	stub_type             StubType
pub mut:
	stub_list &StubList = unsafe { nil }
	id        StubId
}

pub fn new_stub_base(parent &StubElement, stub_type StubType, name string, identifier_text_range TextRange,
	text_range TextRange, data StubData) &StubBase {
	mut stub_list := if parent is StubBase {
		if !isnil(parent.stub_list) { parent.stub_list } else { &StubList{} }
	} else {
		&StubList{}
	}
	parent_id := if !isnil(parent) { parent.id() } else { psi.non_stubbed_element }
	mut stub := &StubBase{
		name:                  name
		text:                  data.text
		comment:               data.comment
		receiver:              data.receiver
		additional:            data.additional
		identifier_text_range: identifier_text_range
		text_range:            text_range
		stub_list:             stub_list
		parent_id:             parent_id
		stub_type:             stub_type
	}
	stub_list.add_stub(mut stub, parent)
	return stub
}

pub fn new_root_stub(path string) &StubBase {
	mut stub_list := &StubList{
		path: path
	}
	mut stub := &StubBase{
		name:      '<root>'
		stub_list: stub_list
		parent_id: -1
		stub_type: .root
	}
	stub_list.add_stub(mut stub, unsafe { nil })
	return stub
}

pub fn (s &StubBase) id() StubId {
	return s.id
}

pub fn (s &StubBase) stub_type() StubType {
	return s.stub_type
}

pub fn (s &StubBase) element_type() bindings.NodeType {
	return match s.stub_type {
		.root { .unknown }
		.function_declaration { .function_declaration }
		.method_declaration { .function_declaration }
		.static_method_declaration { .static_method_declaration }
		.static_receiver { .static_receiver }
		.receiver { .receiver }
		.signature { .signature }
		.parameter_list { .parameter_list }
		.parameter_declaration { .parameter_declaration }
		.struct_declaration { .struct_declaration }
		.interface_declaration { .interface_declaration }
		.interface_method_declaration { .interface_method_definition }
		.field_declaration { .struct_field_declaration }
		.constant_declaration { .const_definition }
		.type_alias_declaration { .type_declaration }
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
		//
		.visibility_modifiers { .visibility_modifiers }
		.import_list { .import_list }
		.import_declaration { .import_declaration }
		.import_spec { .import_spec }
		.import_path { .import_path }
		.import_name { .import_name }
		.import_alias { .import_alias }
		.module_clause { .module_clause }
		.reference_expression { .reference_expression }
		.generic_parameters { .generic_parameters }
		.generic_parameter { .generic_parameter }
		.global_variable { .global_var_definition }
		.embedded_definition { .embedded_definition }
	}
}

pub fn (s StubBase) name() string {
	return s.name
}

pub fn (s StubBase) text() string {
	return s.text
}

pub fn (s StubBase) receiver() string {
	return s.receiver
}

pub fn (s StubBase) text_range() TextRange {
	return s.identifier_text_range
}

fn (s StubBase) get_psi() ?PsiElement {
	return StubbedElementType{}.create_psi(s)
}

fn (s &StubBase) parent_of_type(typ StubType) ?StubElement {
	mut res := &StubBase{
		...s
	}
	for {
		parent := res.parent_stub()?

		if parent is StubBase {
			res = parent
		} else {
			return none
		}

		if res.stub_type == typ {
			return res
		}
	}

	return none
}

fn (s &StubBase) sibling_of_type_backward(typ StubType) ?StubElement {
	mut res := &StubBase{
		...s
	}
	for {
		prev := res.prev_sibling()?

		if prev is StubBase {
			res = prev
		} else {
			return none
		}

		if res.stub_type == typ {
			return res
		}
	}

	return none
}

fn (s &StubBase) parent_stub() ?&StubElement {
	if s.parent_id == -1 {
		return none
	}

	return s.stub_list.get_stub(s.parent_id) or { return none }
}

fn (s &StubBase) get_child_by_type(typ StubType) ?StubElement {
	return s.stub_list.get_child_by_type(s.id, typ)
}

fn (s &StubBase) get_children_by_type(typ StubType) []StubElement {
	return s.stub_list.get_children_stubs(s.id).filter(it.stub_type() == typ)
}

fn (s &StubBase) has_child_of_type(typ StubType) bool {
	return s.stub_list.has_child_of_type(s.id, typ)
}

fn (s &StubBase) prev_sibling() ?&StubElement {
	return s.stub_list.prev_sibling(s.id)
}

fn (s &StubBase) next_sibling() ?&StubElement {
	return s.stub_list.next_sibling(s.id)
}

pub fn (s &StubBase) children_stubs() []StubElement {
	return s.stub_list.get_children_stubs(s.id)
}

fn (s &StubBase) first_child() ?&StubElement {
	return s.stub_list.first_child(s.id)
}

fn (s &StubBase) last_child() ?&StubElement {
	return s.stub_list.last_child(s.id)
}
