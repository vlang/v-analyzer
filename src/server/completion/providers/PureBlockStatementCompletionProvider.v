module providers

import server.completion
import lsp

pub struct PureBlockStatementCompletionProvider {}

fn (k &PureBlockStatementCompletionProvider) is_available(ctx &completion.CompletionContext) bool {
	return ctx.is_statement && !ctx.after_dot && !ctx.after_at
}

fn (mut k PureBlockStatementCompletionProvider) add_completion(ctx &completion.CompletionContext, mut result completion.CompletionResultSet) {
	result.add_element(lsp.CompletionItem{
		label: 'defer { ... }'
		kind: .keyword
		insert_text: 'defer {\n\t$0\n}'
		insert_text_format: .snippet
		insert_text_mode: .adjust_indentation
	})
}
