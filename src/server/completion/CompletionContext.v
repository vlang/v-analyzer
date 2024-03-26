module completion

import analyzer.psi
import lsp

pub const dummy_identifier = 'vAnalyzerRulezzz'

pub struct CompletionContext {
pub:
	element      psi.PsiElement
	position     lsp.Position
	offset       u64
	trigger_kind lsp.CompletionTriggerKind
pub mut:
	is_test_file        bool
	is_start_of_file    bool
	is_top_level        bool
	is_statement        bool
	is_expression       bool
	is_type_reference   bool
	is_import_name      bool
	is_attribute        bool
	is_assert_statement bool
	inside_loop         bool
	after_dot           bool
	after_at            bool
	// if the struct is initialized with keys
	// struct Foo { a: int, b: int }
	inside_struct_init_with_keys bool
}

pub fn (c CompletionContext) expression() bool {
	return c.is_expression && !c.after_dot && !c.after_at && !c.inside_struct_init_with_keys
}

pub fn (mut c CompletionContext) compute() {
	containing_file := c.element.containing_file
	c.is_test_file = containing_file.is_test_file()

	range := c.element.text_range()
	line := range.line
	if line < 3 {
		c.is_start_of_file = true
	}
	symbol_at := containing_file.symbol_at(range)
	c.after_dot = symbol_at == `.`
	c.after_at = c.element.get_text().starts_with('@')

	parent := c.element.parent() or { return }

	if parent is psi.ImportName {
		c.is_import_name = true
	}

	if parent.node.type_name == .reference_expression {
		if grand := parent.parent() {
			// do not consider as reference_expression if it is inside an attribute
			c.is_expression = grand !is psi.ValueAttribute

			if grand.node.type_name == .element_list {
				c.inside_struct_init_with_keys = true
			}

			if _ := grand.prev_sibling_of_type(.keyed_element) {
				c.inside_struct_init_with_keys = true
			}
		}
	}

	if parent.node.type_name == .keyed_element {
		c.inside_struct_init_with_keys = true
	}

	if parent.node.type_name == .type_reference_expression {
		c.is_type_reference = true
	}

	if parent.node.type_name == .for_statement {
		c.inside_loop = true
	}

	if grand := parent.parent() {
		if grand.node.type_name == .simple_statement {
			c.is_statement = true
		}
		if grand.node.type_name == .assert_statement {
			c.is_assert_statement = true
		}
		if grand.node.type_name == .value_attribute {
			c.is_attribute = true
		}

		if grand.node.type_name == .for_statement {
			c.inside_loop = true
		}

		if grand_grand := grand.parent() {
			if grand_grand.node.type_name == .source_file {
				c.is_top_level = true
			}

			if grand_grand.node.type_name == .for_statement {
				c.inside_loop = true
			}
		}
	}

	if !c.inside_loop {
		// long way if the first three parents up are not loops
		c.inside_loop = c.element.inside(.for_statement)
	}
}
