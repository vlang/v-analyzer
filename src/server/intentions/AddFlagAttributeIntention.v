module intentions

import lsp
import analyzer.psi
import server.tform
import server.file_diff

pub struct AddFlagAttributeIntention {
	id   string = 'v-analyzer.add_flag_attribute'
	name string = 'Add [flag] attribute'
}

fn (_ &AddFlagAttributeIntention) is_available(ctx IntentionContext) bool {
	pos := tform.lsp_position_to_position(ctx.position)
	declaration := find_declaration_at_pos(ctx.containing_file, pos) or { return false }

	if declaration is psi.EnumDeclaration {
		return !declaration.is_flag()
	}

	return false
}

fn (_ &AddFlagAttributeIntention) invoke(ctx IntentionContext) ?lsp.WorkspaceEdit {
	pos := tform.lsp_position_to_position(ctx.position)

	declaration := find_declaration_at_pos(ctx.containing_file, pos) or { return none }
	start_line := declaration.identifier_text_range().line
	uri := ctx.containing_file.uri()

	mut diff := file_diff.Diff.for_file(uri)
	diff.append_as_prev_line(start_line, '[flag]')
	return diff.to_workspace_edit()
}
