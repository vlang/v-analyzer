module server

import lsp
import loglib
import analyzer.psi
import server.tform

pub fn (mut ls LanguageServer) prepare_rename(params lsp.PrepareRenameParams) !lsp.PrepareRenameResult {
	uri := params.text_document.uri.normalize()
	file := ls.get_file(uri) or { return error('cannot rename element from not opened file') }

	offset := file.find_offset(params.position)
	element := file.psi_file.find_element_at(offset) or {
		loglib.with_fields({
			'offset': offset.str()
		}).warn('Cannot find element')
		return error('cannot find element at ' + offset.str())
	}

	if element !is psi.Identifier {
		return error('cannot rename non identifier element')
	}

	resolved := resolve_identifier(element)
	if resolved !is psi.VarDefinition {
		return error('cannot rename non-variable element')
	}

	if resolved is psi.PsiNamedElement {
		element_text_range := resolved.identifier_text_range()

		return lsp.PrepareRenameResult{
			range: tform.text_range_to_lsp_range(element_text_range)
			placeholder: ''
		}
	}

	return error('')
}

fn resolve_identifier(element psi.PsiElement) psi.PsiElement {
	parent := element.parent() or { return element }
	resolved := if parent is psi.ReferenceExpression {
		parent.resolve() or { return element }
	} else if parent is psi.TypeReferenceExpression {
		parent.resolve() or { return element }
	} else {
		parent
	}

	return resolved
}
