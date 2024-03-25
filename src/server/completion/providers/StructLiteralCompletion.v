module providers

import analyzer.psi
import server.completion
import analyzer.psi.types

// Describes struct literal completion variants that should be suggested.
pub enum Variants {
	// Only struct field names should be suggested.
	// Indicates that field:value initializers are used in this struct literal.
	// For example, `Struct{field1: "", caret}`.
	field_name_only
	// Only values should be suggested.
	// Indicates that value initializers are used in this struct literal.
	// For example, `Struct{"", caret}`.
	value_only
	// Both struct field names and values should be suggested.
	// Indicates that there's no reliable way to determine whether field:value or value initializers are used.
	// Example 1: `Struct{caret}`.
	// Example 2: `Struct{field1:"", "", caret}`
	both
	// Indicates that struct literal completion should not be available.
	none_
}

pub struct StructLiteralCompletion {}

pub fn (s &StructLiteralCompletion) allowed_variants(ctx &completion.CompletionContext, ref psi.ReferenceExpressionBase) Variants {
	if ctx.after_dot {
		return .none_
	}

	element := ref as psi.PsiElement

	mut parent := element.parent() or { return .none_ }
	for parent is psi.UnaryExpression {
		parent = parent.parent() or { return .none_ }
	}

	if parent.node.type_name != .element_list {
		return .none_
	}

	if type_initializer := parent.parent_nth(2) {
		if type_initializer is psi.TypeInitializer {
			typ := type_initializer.get_type()
			if typ is types.ArrayType {
				// for []int{<caret>}, allow only fields
				return .field_name_only
			}
			if typ is types.ChannelType {
				// for chan int{<caret>}, allow only fields
				return .field_name_only
			}
		}
	}

	field_initializers := s.get_field_initializers(element)

	mut has_value_initializers := false
	mut has_field_value_initializers := false

	for initializer in field_initializers {
		if initializer.is_equal(element) {
			continue
		}

		key_value := initializer.node.type_name == .keyed_element
		has_field_value_initializers = has_field_value_initializers || key_value
		has_value_initializers = has_value_initializers || !key_value
	}

	return if has_field_value_initializers && !has_value_initializers {
		.field_name_only
	} else if !has_field_value_initializers && has_value_initializers {
		.value_only
	} else {
		.both
	}
}

pub fn (s &StructLiteralCompletion) already_assigned_fields(elements []psi.PsiElement) []string {
	mut res := []string{cap: elements.len}

	for element in elements {
		if element.node.type_name == .keyed_element {
			if key := element.first_child() {
				res << key.get_text()
			}
		}
	}

	return res
}

pub fn (s &StructLiteralCompletion) get_field_initializers(element psi.PsiElement) []psi.PsiElement {
	if type_initializer := element.parent_of_type(.type_initializer) {
		if type_initializer is psi.TypeInitializer {
			return type_initializer.element_list()
		}
	}

	return []
}
