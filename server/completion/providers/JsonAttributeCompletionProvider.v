module providers

import analyzer.psi
import server.completion
import lsp
import utils

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
		label:              "json: '${json_name}'"
		kind:               .keyword
		insert_text:        "json: '\${1:${json_name}}'$0"
		insert_text_format: .snippet
	})
}

fn (mut p JsonAttributeCompletionProvider) json_name(field_name string) string {
	without_underscore_and_at := field_name.trim_string_right('_').trim_string_left('@')
	name_to_camelize := if without_underscore_and_at in v_keywords {
		without_underscore_and_at
	} else {
		field_name
	}

	return utils.snake_case_to_camel_case(name_to_camelize)
}

// v_keywords lists V's reserved words. `v.token` no longer exposes a lookup by name.
const v_keywords = ['as', 'asm', 'assert', 'atomic', 'break', 'const', 'continue', 'defer', 'dump',
	'else', 'enum', 'false', 'fn', 'for', '__global', 'go', 'goto', 'if', 'import', 'in', 'interface',
	'is', 'isreftype', '_likely_', 'lock', 'match', 'module', 'mut', 'nil', 'none', '__offsetof',
	'or', 'pub', 'return', 'rlock', 'select', 'shared', 'sizeof', 'spawn', 'static', 'struct',
	'true', 'type', 'typeof', 'union', '_unlikely_', 'unsafe', 'volatile']
