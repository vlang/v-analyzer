module providers

import server.completion
import lsp

pub struct NilKeywordCompletionProvider {}

fn (k &NilKeywordCompletionProvider) is_available(ctx &completion.CompletionContext) bool {
	return ctx.expression()
}

fn (mut k NilKeywordCompletionProvider) add_completion(ctx &completion.CompletionContext, mut result completion.CompletionResultSet) {
	inside_unsafe := ctx.element.inside(.unsafe_expression)

	insert_text := if !inside_unsafe {
		'unsafe { nil }'
	} else {
		'nil'
	}

	result.add_element(lsp.CompletionItem{
		label: 'nil'
		kind: .keyword
		insert_text: insert_text
	})
}
