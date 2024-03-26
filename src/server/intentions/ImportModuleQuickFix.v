module intentions

import lsp
import analyzer.psi
import server.tform
import server.file_diff

pub struct ImportModuleQuickFix {
	id   string = 'v-analyzer.import_module'
	name string = 'Import module'
}

fn (_ &ImportModuleQuickFix) is_matched_message(msg string) bool {
	return msg.contains('undefined ident')
}

fn (_ &ImportModuleQuickFix) is_available(ctx IntentionContext) bool {
	pos := tform.lsp_position_to_position(ctx.position)
	element := ctx.containing_file.find_element_at_pos(pos) or { return false }
	reference_expression := element.parent_of_type(.reference_expression) or { return false }
	if reference_expression is psi.ReferenceExpression {
		if _ := reference_expression.qualifier() {
			return false
		}

		module_name := reference_expression.get_text()
		modules := stubs_index.get_modules_by_name(module_name)
		if modules.len == 0 {
			return false
		}

		return true
	}
	return false
}

fn (_ &ImportModuleQuickFix) invoke(ctx IntentionContext) ?lsp.WorkspaceEdit {
	uri := ctx.containing_file.uri()
	pos := tform.lsp_position_to_position(ctx.position)
	element := ctx.containing_file.find_element_at_pos(pos)?
	reference_expression := element.parent_of_type(.reference_expression)?

	module_name := reference_expression.get_text()
	modules := stubs_index.get_modules_by_name(module_name)
	if modules.len == 0 {
		return none
	}

	mod := modules.first()
	file := mod.containing_file
	module_fqn := file.module_fqn()

	imports := ctx.containing_file.get_imports()

	mut extra_newline := ''
	mut line_to_insert := 0
	if imports.len > 0 {
		line_to_insert = imports.last().text_range().line + 1
	} else if mod_clause := ctx.containing_file.module_clause() {
		line_to_insert = mod_clause.text_range().line + 2
		extra_newline = '\n'
	} else {
		extra_newline = '\n'
		line_to_insert = 0
	}

	mut diff := file_diff.Diff.for_file(uri)
	diff.append_as_prev_line(line_to_insert, 'import ' + module_fqn + extra_newline)
	return diff.to_workspace_edit()
}
