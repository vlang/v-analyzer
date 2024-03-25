module file_diff

import lsp

pub struct Edit {
	range    lsp.Range
	new_text string
}

pub struct Diff {
	uri lsp.DocumentUri
mut:
	edits []Edit
}

pub fn Diff.for_file(uri lsp.DocumentUri) Diff {
	return Diff{
		uri: uri
	}
}

pub fn (mut diff Diff) append_to_begin(line int, text string) {
	diff.append_to(line, 0, text)
}

pub fn (mut diff Diff) append_to(line int, col int, text string) {
	pos := Diff.line_pos(line, col)
	diff.edits << Edit{
		range: lsp.Range{
			start: pos
			end: pos
		}
		new_text: text
	}
}

pub fn (mut diff Diff) append_as_prev_line(line int, text string) {
	pos := Diff.line_begin_pos(line)
	diff.edits << Edit{
		range: lsp.Range{
			start: pos
			end: pos
		}
		new_text: '${text}\n'
	}
}

pub fn (mut diff Diff) append_as_next_line(line int, text string) {
	pos := Diff.line_begin_pos(line)
	diff.edits << Edit{
		range: lsp.Range{
			start: pos
			end: pos
		}
		new_text: '\n${text}'
	}
}

pub fn (mut diff Diff) to_workspace_edit() lsp.WorkspaceEdit {
	return lsp.WorkspaceEdit{
		changes: {
			diff.uri: diff.edits.map(lsp.TextEdit{
				range: it.range
				new_text: it.new_text
			})
		}
	}
}

fn Diff.line_begin_pos(line int) lsp.Position {
	return lsp.Position{
		line: line
		character: 0
	}
}

fn Diff.line_pos(line int, col int) lsp.Position {
	return lsp.Position{
		line: line
		character: col
	}
}
