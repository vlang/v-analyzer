module providers

import analyzer.psi
import server.completion
import lsp
import utils
import v.token

pub struct JsonAttributeCompletionProvider {}

fn (p &JsonAttributeCompletionProvider) is_available(ctx &completion.CompletionContext) bool {
	if !ctx.is_attribute {
		return false
	}
	return ctx.element.inside(.struct_field_declaration)
}

fn (mut p JsonAttributeCompletionProvider) add_completion(ctx &completion.CompletionContext, mut result completion.CompletionResultSet) {
	field_declaration := ctx.element.parent_of_type(.struct_field_declaration) or { return }
	name := if field_declaration is psi.FieldDeclaration {
		field_declaration.name()
	} else {
		return
	}

	json_name := p.json_name(name)

	result.add_element(lsp.CompletionItem{
		label: "json: '${json_name}'"
		kind: .keyword
		insert_text: "json: '\${1:${json_name}}'$0"
		insert_text_format: .snippet
	})
}

fn (mut p JsonAttributeCompletionProvider) json_name(field_name string) string {
	without_underscore_and_at := field_name.trim_string_right('_').trim_string_left('@')
	name_to_camelize := if token.is_key(without_underscore_and_at) {
		without_underscore_and_at
	} else {
		field_name
	}

	return utils.snake_case_to_camel_case(name_to_camelize)
}
