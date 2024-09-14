module server

import lsp
import server.semantic
import time

const max_line_for_resolve_semantic_tokens = 1000
const max_line_for_any_semantic_tokens = 10000

pub fn (mut ls LanguageServer) semantic_tokens(text_document lsp.TextDocumentIdentifier, range lsp.Range) ?lsp.SemanticTokens {
	if ls.cfg.enable_semantic_tokens == .none_ {
		return none
	}

	uri := text_document.uri.normalize()
	file := ls.get_file(uri)?

	lines := file.psi_file.source_text.count('\n')

	if lines > max_line_for_any_semantic_tokens {
		// File too large, don't compute any tokens.
		return lsp.SemanticTokens{}
	}

	if lines > max_line_for_resolve_semantic_tokens || ls.cfg.enable_semantic_tokens == .syntax {
		// We don't want to send too many tokens (and compute it), so we just
		// send dumb-aware tokens for large files.
		dumb_aware_visitor := semantic.new_dumb_aware_semantic_visitor(range, file.psi_file)
		tokens := dumb_aware_visitor.accept(file.psi_file.root)
		return lsp.SemanticTokens{
			result_id: time.now().unix().str()
			data:      semantic.encode(tokens)
		}
	}

	mut result := semantic.new_dumb_aware_semantic_visitor(range, file.psi_file)
		.accept(file.psi_file.root)
	resolve_tokens := semantic.new_resolve_semantic_visitor(range, file.psi_file)
		.accept(file.psi_file.root)

	result << resolve_tokens

	return lsp.SemanticTokens{
		result_id: time.now().unix().str()
		data:      semantic.encode(result)
	}
}
