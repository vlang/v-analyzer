module semantic

import analyzer.psi

@[json_as_number]
enum SemanticTypes as u32 {
	namespace
	type_
	class
	enum_
	interface_
	struct_
	type_parameter
	parameter
	variable
	property
	enum_member
	event
	function
	method
	macro
	keyword
	modifier
	comment
	string
	number
	regexp
	operator
	decorator
}

pub struct SemanticToken {
	line  u32
	start u32
	len   u32
	typ   SemanticTypes
	mods  []string
}

@[inline]
fn element_to_semantic(element psi.AstNode, typ SemanticTypes, modifiers ...string) SemanticToken {
	start_point := element.start_point()
	return SemanticToken{
		line:  start_point.row
		start: start_point.column
		len:   element.text_length()
		typ:   typ
		mods:  modifiers
	}
}
