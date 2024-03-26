module providers

import server.completion
import lsp
import os

pub struct ModuleNameCompletionProvider {}

fn (_ &ModuleNameCompletionProvider) is_available(ctx &completion.CompletionContext) bool {
	no_module_clause := if _ := ctx.element.containing_file.module_name() {
		false
	} else {
		true
	}
	return ctx.is_start_of_file && ctx.is_top_level && no_module_clause
}

fn (mut p ModuleNameCompletionProvider) add_completion(ctx &completion.CompletionContext, mut result completion.CompletionResultSet) {
	dir := os.dir(ctx.element.containing_file.path)
	dir_name := p.transform_module_name(os.file_name(dir))

	result.add_element(lsp.CompletionItem{
		label: 'module ${dir_name}'
		kind: .keyword
		insert_text_format: .snippet
		insert_text: 'module ${dir_name}'
	})

	result.add_element(lsp.CompletionItem{
		label: 'module main'
		kind: .keyword
		insert_text: 'module main'
	})
}

fn (mut _ ModuleNameCompletionProvider) transform_module_name(raw_name string) string {
	return raw_name
		.replace('-', '_')
		.replace(' ', '_')
		.to_lower()
}
