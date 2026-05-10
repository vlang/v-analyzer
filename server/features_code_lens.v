module server

import lsp
import server.code_lens

pub fn (mut ls LanguageServer) code_lens(params lsp.CodeLensParams) ?[]lsp.CodeLens {
	if !ls.cfg.code_lens.enable {
		return []
	}

	uri := params.text_document.uri.normalize()
	file := ls.get_file(uri)?

	mut visitor := code_lens.new_visitor(ls.cfg.code_lens, uri, file.psi_file)
	visitor.accept(file.psi_file.root())
	return visitor.result()
}
