module server

import lsp
import loglib
import json
import server.intentions

pub struct IntentionData {
pub:
	file_uri string
	position lsp.Position
}

pub fn (mut ls LanguageServer) execute_command(params lsp.ExecuteCommandParams) ? {
	mut intention := ls.find_intention_or_quickfix(params.command)?

	arguments := json.decode([]string, params.arguments) or { []string{} }

	argument := json.decode(IntentionData, arguments[0]) or {
		loglib.with_fields({
			'command':  params.command
			'argument': params.arguments
		}).warn('Got invalid argument')
		return
	}

	file_uri := argument.file_uri
	file := ls.get_file(file_uri)?
	pos := argument.position

	ctx := intentions.IntentionContext.from(file.psi_file, pos)
	edits := intention.invoke(ctx) or { return }

	ls.client.apply_edit(edit: edits)
}

pub fn (mut ls LanguageServer) find_intention_or_quickfix(name string) ?intentions.Intention {
	if i := ls.intentions[name] {
		return i
	}

	if qf := ls.compiler_quick_fixes[name] {
		return qf as intentions.Intention
	}

	return none
}
