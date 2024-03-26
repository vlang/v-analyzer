module completion

pub interface CompletionProvider {
	is_available(ctx &CompletionContext) bool
mut:
	add_completion(ctx &CompletionContext, mut result CompletionResultSet)
}
