module providers

import analyzer.psi
import server.completion
import analyzer.psi.types
import analyzer.lang
import lsp

pub struct ReturnCompletionProvider {}

fn (_ &ReturnCompletionProvider) is_available(ctx &completion.CompletionContext) bool {
	return ctx.is_statement && !ctx.after_at
}

fn (mut _ ReturnCompletionProvider) add_completion(ctx &completion.CompletionContext, mut result completion.CompletionResultSet) {
	element := ctx.element

	parent_function := element.parent_of_any_type(.function_declaration, .function_literal) or {
		return
	}
	signature := if parent_function is psi.SignatureOwner {
		parent_function.signature() or { return }
	} else {
		return
	}

	function_type := signature.get_type()
	if function_type is types.FunctionType {
		has_result_type := !function_type.no_result
		result_type := function_type.result
		if result_type is types.PrimitiveType {
			if result_type.name == 'bool' {
				result.add_element(lsp.CompletionItem{
					label: 'return true'
					kind: .text
				})
				result.add_element(lsp.CompletionItem{
					label: 'return false'
					kind: .text
				})
			}
		}

		if has_result_type {
			zero_value := lang.get_zero_value_for(result_type)
			result.add_element(lsp.CompletionItem{
				label: 'return ${zero_value}'
				kind: .text
			})
		}

		label := if !has_result_type {
			'return'
		} else {
			'return '
		}

		result.add_element(lsp.CompletionItem{
			label: label
			kind: .text
		})
	}
}
