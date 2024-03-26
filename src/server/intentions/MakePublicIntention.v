module intentions

import lsp
import analyzer.psi
import server.tform
import server.file_diff

pub struct MakePublicIntention {
	id   string = 'v-analyzer.make_public'
	name string = 'Make public'
}

fn (_ &MakePublicIntention) is_available(ctx IntentionContext) bool {
	pos := tform.lsp_position_to_position(ctx.position)
	declaration := find_declaration_at_pos(ctx.containing_file, pos) or { return false }
	return !declaration.is_public()
}

fn (_ &MakePublicIntention) invoke(ctx IntentionContext) ?lsp.WorkspaceEdit {
	pos := tform.lsp_position_to_position(ctx.position)
	declaration := find_declaration_at_pos(ctx.containing_file, pos)?

	uri := ctx.containing_file.uri()

	mut start_line := declaration.identifier_text_range().line
	if declaration is psi.ConstantDefinition {
		decl := declaration.parent()?
		if decl is psi.ConstantDeclaration {
			start_line = decl.text_range().line
		}
	}

	mut diff := file_diff.Diff.for_file(uri)
	diff.append_to_begin(start_line, 'pub ')
	return diff.to_workspace_edit()
}
