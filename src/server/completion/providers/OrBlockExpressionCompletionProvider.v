module providers

import server.completion
import lsp

pub struct OrBlockExpressionCompletionProvider {}

fn (k &OrBlockExpressionCompletionProvider) is_available(ctx &completion.CompletionContext) bool {
	return ctx.expression()
}

fn (mut k OrBlockExpressionCompletionProvider) add_completion(ctx &completion.CompletionContext, mut result completion.CompletionResultSet) {
	result.add_element(lsp.CompletionItem{
		label: 'or { ... }'
		kind: .keyword
		insert_text: 'or { $0 }'
		insert_text_format: .snippet
	})

	result.add_element(lsp.CompletionItem{
		label: 'or { panic(err) }'
		kind: .keyword
		insert_text: 'or { panic(err) }'
	})
}
