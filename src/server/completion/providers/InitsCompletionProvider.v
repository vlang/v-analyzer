module providers

import server.completion
import lsp

pub struct InitsCompletionProvider {}

fn (_ &InitsCompletionProvider) is_available(ctx &completion.CompletionContext) bool {
	return ctx.expression()
}

fn (mut _ InitsCompletionProvider) add_completion(ctx &completion.CompletionContext, mut result completion.CompletionResultSet) {
	result.add_element(lsp.CompletionItem{
		label: 'chan int{}'
		kind: .snippet
		detail: ''
		insert_text: 'chan \${1:int}{}$0'
		insert_text_format: .snippet
	})

	result.add_element(lsp.CompletionItem{
		label: 'map[string]int{}'
		kind: .snippet
		detail: ''
		insert_text: 'map[\${1:string}]\${2:int}{}$0'
		insert_text_format: .snippet
	})

	result.add_element(lsp.CompletionItem{
		label: 'thread int{}'
		kind: .snippet
		detail: ''
		insert_text: 'thread \${1:int}{}$0'
		insert_text_format: .snippet
	})
}
