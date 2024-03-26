module providers

import server.completion
import lsp

pub struct PureBlockExpressionCompletionProvider {}

fn (k &PureBlockExpressionCompletionProvider) is_available(ctx &completion.CompletionContext) bool {
	return ctx.expression()
}

fn (mut k PureBlockExpressionCompletionProvider) add_completion(ctx &completion.CompletionContext, mut result completion.CompletionResultSet) {
	one_line := if parent := ctx.element.parent_nth(2) {
		if parent.node.type_name == .simple_statement {
			false
		} else {
			true
		}
	} else {
		true
	}

	insert_text := if one_line {
		'unsafe { $0 }'
	} else {
		'unsafe {\n\t$0\n}'
	}

	result.add_element(lsp.CompletionItem{
		label: 'unsafe { ... }'
		kind: .keyword
		insert_text: insert_text
		insert_text_format: .snippet
		insert_text_mode: .adjust_indentation
	})
}
