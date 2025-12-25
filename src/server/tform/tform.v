module tform

import lsp
import analyzer.psi

// elements_to_locations converts an array of PsiElements to a slice of LSP locations.
pub fn elements_to_locations(elements []psi.PsiElement) []lsp.Location {
	mut locations := []lsp.Location{cap: elements.len}
	for element in elements {
		file := element.containing_file() or { continue }
		range := if element is psi.PsiNamedElement {
			element.identifier_text_range()
		} else {
			element.text_range()
		}
		locations << lsp.Location{
			uri:   file.uri()
			range: text_range_to_lsp_range(range)
		}
	}
	return locations
}

// text_range_to_lsp_range converts a TextRange to an LSP Range.
pub fn text_range_to_lsp_range(pos psi.TextRange) lsp.Range {
	return lsp.Range{
		start: lsp.Position{
			line:      pos.line
			character: pos.column
		}
		end:   lsp.Position{
			line:      pos.end_line
			character: pos.end_column
		}
	}
}

// elements_to_text_edits converts an array of PsiElements to an array of LSP TextEdits.
// If element is a PsiNamedElement, the edit will be applied to the identifier.
// Otherwise, the edit will be applied to the entire element.
pub fn elements_to_text_edits(elements []psi.PsiElement, new_name string) []lsp.TextEdit {
	mut result := []lsp.TextEdit{cap: elements.len}

	for element in elements {
		range := if element is psi.PsiNamedElement {
			element.identifier_text_range()
		} else {
			element.text_range()
		}
		result << lsp.TextEdit{
			range:    text_range_to_lsp_range(range)
			new_text: new_name
		}
	}

	return result
}

pub fn position_to_lsp_position(pos psi.Position) lsp.Position {
	return lsp.Position{
		line:      pos.line
		character: pos.character
	}
}

pub fn lsp_position_to_position(pos lsp.Position) psi.Position {
	return psi.Position{
		line:      pos.line
		character: pos.character
	}
}
