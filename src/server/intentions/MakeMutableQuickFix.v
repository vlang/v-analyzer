module intentions

import lsp
import analyzer.psi
import server.file_diff
import server.tform

pub struct MakeMutableQuickFix {
	id   string = 'v-analyzer.make_mutable'
	name string = 'Make mutable'
}

fn (_ &MakeMutableQuickFix) is_matched_message(msg string) bool {
	return msg.contains('is immutable')
}

fn (_ &MakeMutableQuickFix) is_available(_ IntentionContext) bool {
	return true
}

fn (_ &MakeMutableQuickFix) invoke(ctx IntentionContext) ?lsp.WorkspaceEdit {
	pos := tform.lsp_position_to_position(ctx.position)
	ref := find_reference_at_pos(ctx.containing_file, pos)?
	uri := ctx.containing_file.uri()

	mut diff := file_diff.Diff.for_file(uri)

	resolved := ref.resolve()?
	text_range := resolved.text_range()
	if resolved is psi.MutabilityOwner {
		if resolved.is_mutable() {
			return none
		}

		mut column := text_range.column

		if resolved is psi.Receiver {
			column += 1
		}

		diff.append_to(text_range.line, column, 'mut ')
	}

	return diff.to_workspace_edit()
}
