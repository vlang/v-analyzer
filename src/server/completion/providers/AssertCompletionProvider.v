module providers

import server.completion
import lsp

pub struct AssertCompletionProvider {}

fn (_ &AssertCompletionProvider) is_available(ctx &completion.CompletionContext) bool {
	if !ctx.is_test_file {
		return false
	}
	return ctx.is_statement || ctx.is_assert_statement
}

fn (mut _ AssertCompletionProvider) add_completion(ctx &completion.CompletionContext, mut result completion.CompletionResultSet) {
	result.add_element(lsp.CompletionItem{
		label: 'assert expr'
		kind: .keyword
		insert_text_format: .snippet
		insert_text: 'assert \${1:expr}'
	})

	result.add_element(lsp.CompletionItem{
		label: 'assert expr, message'
		kind: .keyword
		insert_text_format: .snippet
		insert_text: "assert \${1:expr}, '\${2:message}'$0"
	})
}
