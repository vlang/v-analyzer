module providers

import lsp
import strings
import analyzer.psi
import analyzer.lang
import server.completion

pub struct ReferenceCompletionProcessor {
	file       &psi.PsiFile
	module_fqn string
	root       string
	ctx        &completion.CompletionContext
mut:
	result map[string]lsp.CompletionItem
}

pub fn (mut c ReferenceCompletionProcessor) elements() []lsp.CompletionItem {
	return c.result.values()
}

fn (mut c ReferenceCompletionProcessor) is_local_resolve(element psi.PsiElement) bool {
	element_module_fqn := element.containing_file.module_fqn()
	equal := c.module_fqn == element_module_fqn
	if equal && c.module_fqn == 'main' {
		// We check that the module matches, but if it is main, then we need to check
		// that the file is in the workspace.
		return element.containing_file.path.starts_with(c.root)
	}
	return equal
}

fn (mut c ReferenceCompletionProcessor) execute(element psi.PsiElement) bool {
	is_public, name := if element is psi.PsiNamedElement {
		element.is_public(), element.name()
	} else {
		true, ''
	}
	local_resolve := c.is_local_resolve(element)

	if !is_public && !local_resolve {
		return true
	}

	if element is psi.VarDefinition {
		c.add_item(
			label: name
			kind: .variable
			detail: element.get_type().readable_name()
			label_details: lsp.CompletionItemLabelDetails{
				description: element.get_type().readable_name()
			}
			documentation: ''
			insert_text: name
			insert_text_format: .plain_text
			sort_text: '0${name}' // variables should go first
		)
	}

	if element is psi.ParameterDeclaration {
		c.add_item(
			label: name
			kind: .variable
			detail: element.get_type().readable_name()
			label_details: lsp.CompletionItemLabelDetails{
				description: element.get_type().readable_name()
			}
			documentation: ''
			insert_text: name
			insert_text_format: .plain_text
			sort_text: '0${name}' // parameters should go first
		)
	}

	if element is psi.Receiver {
		c.add_item(
			label: element.name()
			kind: .variable
			detail: element.get_type().readable_name()
			label_details: lsp.CompletionItemLabelDetails{
				description: element.get_type().readable_name()
			}
			documentation: ''
			insert_text: element.name()
			insert_text_format: .plain_text
		)
	}

	if element is psi.FunctionOrMethodDeclaration {
		receiver_text := if receiver := element.receiver() {
			receiver.get_text() + ' '
		} else {
			''
		}

		mut insert_name := element.name()
		if name.starts_with('$') {
			insert_name = insert_name[1..]
		}

		signature := element.signature() or { return true }
		has_params := signature.parameters().len > 0

		generic_parameters_text := if generic_parameters := element.generic_parameters() {
			generic_parameters.text_presentation()
		} else {
			''
		}

		text_ranga := c.ctx.element.text_range()
		symbol := c.ctx.element.containing_file.symbol_at(psi.TextRange{
			line: text_ranga.line
			column: text_ranga.end_column + 1
		})
		paren_after_cursor := symbol == `(`

		mut insert_text_builder := strings.new_builder(20)
		insert_text_builder.write_string(insert_name)

		// we don't want add extra parentheses if the cursor is before the parentheses
		// It happens when user replaces the function name in the call, for example:
		// 1. foo()
		// 2. remove foo, type bar and autocomplete
		// 3. bar()
		// without this check we would get bar()()
		if !paren_after_cursor {
			if has_params {
				insert_text_builder.write_string('($1)')
			} else {
				insert_text_builder.write_string('()')
			}
		}
		insert_text_builder.write_string('$0')

		c.add_item(
			label: '${name}'
			kind: if receiver_text == '' { .function } else { .method }
			label_details: lsp.CompletionItemLabelDetails{
				detail: signature.get_text()
			}
			detail: 'fn ${receiver_text}${element.name()}${generic_parameters_text}${signature.get_text()}'
			documentation: element.doc_comment()
			insert_text: insert_text_builder.str()
			insert_text_format: .snippet
			sort_text: '1${name}' // functions should go second
		)
	}

	if element is psi.StaticMethodDeclaration {
		receiver_text := if receiver := element.receiver() {
			receiver.get_text() + ' '
		} else {
			''
		}

		mut insert_name := element.name()
		if name.starts_with('$') {
			insert_name = insert_name[1..]
		}

		signature := element.signature() or { return true }
		has_params := signature.parameters().len > 0

		generic_parameters_text := if generic_parameters := element.generic_parameters() {
			generic_parameters.text_presentation()
		} else {
			''
		}

		text_ranga := c.ctx.element.text_range()
		symbol := c.ctx.element.containing_file.symbol_at(psi.TextRange{
			line: text_ranga.line
			column: text_ranga.end_column + 1
		})
		paren_after_cursor := symbol == `(`

		mut insert_text_builder := strings.new_builder(20)
		insert_text_builder.write_string(insert_name)

		// we don't want add extra parentheses if the cursor is before the parentheses
		// It happens when user replaces the function name in the call, for example:
		// 1. foo()
		// 2. remove foo, type bar and autocomplete
		// 3. bar()
		// without this check we would get bar()()
		if !paren_after_cursor {
			if has_params {
				insert_text_builder.write_string('($1)')
			} else {
				insert_text_builder.write_string('()')
			}
		}
		insert_text_builder.write_string('$0')

		c.add_item(
			label: '${name}'
			kind: .method
			label_details: lsp.CompletionItemLabelDetails{
				detail: signature.get_text()
			}
			detail: 'fn ${receiver_text}${element.name()}${generic_parameters_text}${signature.get_text()}'
			documentation: element.doc_comment()
			insert_text: insert_text_builder.str()
			insert_text_format: .snippet
			sort_text: '1${name}' // functions should go second
		)
	}

	if element is psi.StructDeclaration {
		if name == 'map' || name == 'array' {
			// it makes no sense to create these structures directly
			return true
		}

		text_ranga := c.ctx.element.text_range()
		symbol := c.ctx.element.containing_file.symbol_at(psi.TextRange{
			line: text_ranga.line
			column: text_ranga.end_column + 1
		})
		paren_after_cursor := symbol == `{`

		insert_text := if c.ctx.is_type_reference || paren_after_cursor {
			name // if it is a reference to a type, then insert only the name
		} else {
			name + '{$1}$0'
		}

		c.add_item(
			label: name
			kind: .struct_
			detail: ''
			documentation: element.doc_comment()
			insert_text: insert_text
			insert_text_format: .snippet
		)
	}

	if element is psi.ConstantDefinition {
		c.add_item(
			label: element.name()
			kind: .constant
			detail: element.get_type().readable_name()
			label_details: lsp.CompletionItemLabelDetails{
				description: element.get_type().readable_name()
			}
			documentation: element.doc_comment()
			insert_text: element.name()
			insert_text_format: .plain_text
		)
	}

	if element is psi.FieldDeclaration {
		zero_value := lang.get_zero_value_for(element.get_type()).replace('}', '\\}')

		insert_text := if c.ctx.inside_struct_init_with_keys {
			element.name() + ': \${1:${zero_value}}'
		} else {
			element.name()
		}

		c.add_item(
			label: element.name()
			kind: .field
			detail: element.get_type().readable_name()
			label_details: lsp.CompletionItemLabelDetails{
				description: element.get_type().readable_name()
			}
			documentation: element.doc_comment()
			insert_text: insert_text
			insert_text_format: .snippet
		)
	}

	if element is psi.InterfaceMethodDeclaration {
		signature := element.signature() or { return true }
		has_params := signature.parameters().len > 0

		mut insert_text_builder := strings.new_builder(20)
		insert_text_builder.write_string(element.name())
		if has_params {
			insert_text_builder.write_string('($1)')
		} else {
			insert_text_builder.write_string('()')
		}

		owner_name := if owner := element.owner() {
			' of ${owner.name()}'
		} else {
			''
		}
		c.add_item(
			label: element.name()
			kind: .method
			detail: 'fn ${element.name()}${signature.get_text()}'
			label_details: lsp.CompletionItemLabelDetails{
				detail: signature.get_text()
				description: owner_name
			}
			documentation: element.doc_comment()
			insert_text: insert_text_builder.str()
			insert_text_format: .snippet
		)
	}

	if element is psi.EnumDeclaration {
		c.add_item(
			label: element.name()
			kind: .enum_
			detail: ''
			documentation: element.doc_comment()
			insert_text: element.name()
			insert_text_format: .plain_text
		)
	}

	if element is psi.EnumFieldDeclaration {
		c.add_item(
			label: element.name()
			kind: .enum_member
			detail: ''
			documentation: element.doc_comment()
			insert_text: element.name()
			insert_text_format: .plain_text
		)
	}

	if element is psi.GenericParameter {
		c.add_item(
			label: element.name()
			kind: .type_parameter
		)
	}

	if element is psi.GlobalVarDefinition {
		module_name := element.containing_file.module_fqn()
		c.add_item(
			label: element.name()
			label_details: lsp.CompletionItemLabelDetails{
				detail: ' (global defined in ${module_name})'
			}
			kind: .variable
			insert_text: element.name()
		)
	}

	return true
}

fn (mut c ReferenceCompletionProcessor) add_item(item lsp.CompletionItem) {
	if item.label in c.result {
		return
	}

	c.result[item.label] = item
}
