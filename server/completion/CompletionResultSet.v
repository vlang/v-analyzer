module completion

import lsp

pub struct CompletionResultSet {
mut:
	elements []lsp.CompletionItem
}

pub fn (mut c CompletionResultSet) add_element(item lsp.CompletionItem) {
	c.elements << item
}

pub fn (mut c CompletionResultSet) elements() []lsp.CompletionItem {
	return c.elements.filter(it.label != '')
}
