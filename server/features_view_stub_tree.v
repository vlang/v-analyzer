module server

import lsp
import strings
import analyzer.index

pub fn (mut ls LanguageServer) view_stub_tree(params lsp.TextDocumentIdentifier) ?string {
	uri := params.uri.normalize()
	file := ls.get_file(uri) or { return 'file not opened' }

	mut sb := strings.new_builder(100)
	tree := index.build_stub_tree(file.psi_file, params.uri.dir_path())
	tree.print_to(mut sb)

	return sb.str()
}
