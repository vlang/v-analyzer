module providers

import server.completion
import lsp

pub const function_like_keywords = [
	'dump',
	'sizeof',
	'typeof',
	'isreftype',
	'__offsetof',
]

pub struct FunctionLikeCompletionProvider {}

fn (k &FunctionLikeCompletionProvider) is_available(ctx &completion.CompletionContext) bool {
	return ctx.expression()
}

fn (mut k FunctionLikeCompletionProvider) add_completion(ctx &completion.CompletionContext, mut result completion.CompletionResultSet) {
	for keyword in providers.function_like_keywords {
		result.add_element(lsp.CompletionItem{
			label: '${keyword}()'
			kind: .keyword
			insert_text: '${keyword}($1)$0'
			insert_text_format: .snippet
		})
	}
}
