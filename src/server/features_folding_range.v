module server

import lsp
import analyzer.psi

pub fn (mut ls LanguageServer) folding_range(params lsp.FoldingRangeParams) ?[]lsp.FoldingRange {
	uri := params.text_document.uri.normalize()
	file := ls.get_file(uri)?

	mut result := []lsp.FoldingRange{}

	for node in psi.new_tree_walker(file.psi_file.root().node) {
		if node.type_name == .import_list {
			element := psi.create_element(node, file.psi_file)
			decls := element.find_children_by_type(.import_declaration)
			if decls.len < 2 {
				continue
			}

			first := decls.first()
			range := element.text_range()

			first_range := if first is psi.ImportDeclaration {
				spec := first.spec() or { continue }
				spec.text_range()
			} else {
				continue
			}

			result << lsp.FoldingRange{
				start_line: first_range.line
				start_character: first_range.column
				end_line: range.end_line - 2
				end_character: range.end_column
				kind: lsp.folding_range_kind_imports
			}
		}
	}

	return result
}
