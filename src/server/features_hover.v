module server

import lsp
import server.documentation
import loglib
import server.tform

pub fn (mut ls LanguageServer) hover(params lsp.HoverParams) ?lsp.Hover {
	uri := params.text_document.uri.normalize()
	file := ls.get_file(uri)?

	loglib.with_fields({
		'position': params.position.str()
		'uri':      file.uri
	}).warn('Hover request')

	offset := file.find_offset(params.position)
	element := file.psi_file.find_element_at(offset) or {
		loglib.with_fields({
			'offset': offset.str()
		}).warn('Cannot find element')
		return none
	}

	if element.element_type() == .unknown {
		mut provider := documentation.KeywordProvider{}
		if content := provider.documentation(element) {
			return lsp.Hover{
				contents: lsp.hover_markdown_string(content)
				range: tform.text_range_to_lsp_range(element.text_range())
			}
		}
	}

	mut provider := documentation.Provider{}
	doc_element := provider.find_documentation_element(element)?
	if content := provider.documentation(doc_element) {
		return lsp.Hover{
			contents: lsp.hover_markdown_string(content)
			range: tform.text_range_to_lsp_range(element.text_range())
		}
	}

	$if show_ast_on_hover ? {
		// Show AST tree for debugging purposes.
		if grand := element.parent_nth(2) {
			parent := element.parent()?
			this := element.type_name() + ': ' + element.node.type_name.str()
			parent_elem := parent.type_name() + ': ' + parent.node.type_name.str()
			grand_elem := grand.type_name() + ': ' + grand.node.type_name.str()
			return lsp.Hover{
				contents: lsp.hover_markdown_string('```\n' + grand_elem + '\n  ' + parent_elem +
					'\n   ' + this + '\n```')
				range: tform.text_range_to_lsp_range(element.text_range())
			}
		}

		return lsp.Hover{
			contents: lsp.hover_markdown_string(element.type_name() + ': ' +
				element.node.type_name.str())
			range: tform.text_range_to_lsp_range(element.text_range())
		}
	}

	return none
}
