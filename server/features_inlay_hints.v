module server

import lsp
import server.hints

pub fn (mut ls LanguageServer) inlay_hints(params lsp.InlayHintParams) ?[]lsp.InlayHint {
	if !ls.cfg.inlay_hints.enable {
		return none
	}

	uri := params.text_document.uri.normalize()
	file := ls.get_file(uri)?

	mut visitor := hints.InlayHintsVisitor{
		cfg: ls.cfg.inlay_hints
	}
	visitor.accept(file.psi_file.root())
	return visitor.result
}
