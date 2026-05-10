module server

import lsp
import loglib
import server.folding

pub fn (mut ls LanguageServer) folding_range(params lsp.FoldingRangeParams) ?[]lsp.FoldingRange {
	uri := params.text_document.uri.normalize()
	file := ls.get_file(uri) or {
		loglib.with_fields({
			'uri': uri.str()
		}).warn('Folding range requested for unopened file')
		return []
	}

	mut visitor := folding.FoldingVisitor.new(file.psi_file)
	ranges := visitor.accept(file.psi_file.root())

	return ranges
}
