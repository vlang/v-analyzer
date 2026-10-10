module intentions

import lsp
import analyzer.psi
import server.tform
import server.file_diff

pub struct AddHeapAttributeIntention {
	id   string = 'v-analyzer.add_heap_attribute'
	name string = 'Add [heap] attribute'
}

fn (_ &AddHeapAttributeIntention) is_available(ctx IntentionContext) bool {
	pos := tform.lsp_position_to_position(ctx.position)
	declaration := find_declaration_at_pos(ctx.containing_file, pos) or { return false }

	if declaration is psi.StructDeclaration {
		return !declaration.is_heap()
	}

	return false
}

fn (_ &AddHeapAttributeIntention) invoke(ctx IntentionContext) ?lsp.WorkspaceEdit {
	pos := tform.lsp_position_to_position(ctx.position)

	declaration := find_declaration_at_pos(ctx.containing_file, pos) or { return none }
	start_line := declaration.identifier_text_range().line
	uri := ctx.containing_file.uri()

	mut diff := file_diff.Diff.for_file(uri)
	diff.append_as_prev_line(start_line, '[heap]')
	return diff.to_workspace_edit()
}
