module server

import lsp
import server.tform
import analyzer.psi

pub fn (mut ls LanguageServer) workspace_symbol(_ lsp.WorkspaceSymbolParams) ?[]lsp.WorkspaceSymbol {
	workspace_elements := ls.indexing_mng.stub_index.get_all_elements_from(.workspace)

	mut workspace_symbols := []lsp.WorkspaceSymbol{cap: workspace_elements.len}

	for elem in workspace_elements {
		uri := elem.containing_file.uri()
		module_name := elem.containing_file.module_name() or { '' }

		if elem is psi.PsiNamedElement {
			name := elem.name()
			if name == '_' {
				continue
			}

			fqn := if module_name == '' { name } else { module_name + '.' + name }

			text_range := elem.identifier_text_range()
			workspace_symbols << lsp.WorkspaceSymbol{
				name: fqn
				kind: symbol_kind(elem as psi.PsiElement) or { continue }
				location: lsp.Location{
					uri: uri
					range: tform.text_range_to_lsp_range(text_range)
				}
			}
		}
	}

	return workspace_symbols
}
