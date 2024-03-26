module server

import lsp
import os
import server.tform

const temp_formatting_file_path = os.join_path(os.temp_dir(), 'v-analyzer-formatting-temp.v')

pub fn (mut ls LanguageServer) formatting(params lsp.DocumentFormattingParams) ![]lsp.TextEdit {
	uri := params.text_document.uri.normalize()
	file := ls.get_file(uri) or { return error('Cannot format not opened file') }

	os.write_file(server.temp_formatting_file_path, file.psi_file.source_text) or {
		return error('Cannot write temp file for formatting: ${err}')
	}

	mut fmt_proc := ls.launch_tool('fmt', server.temp_formatting_file_path)!
	defer {
		fmt_proc.close()
	}
	fmt_proc.wait()

	if fmt_proc.code != 0 {
		errors := fmt_proc.stderr_slurp().trim_space()
		ls.client.show_message(errors, .info)
		return error('Formatting failed: ${errors}')
	}

	mut output := fmt_proc.stdout_slurp()
	$if windows {
		output = output.replace('\r\r', '\r')
	}

	return [
		lsp.TextEdit{
			range: tform.text_range_to_lsp_range(file.psi_file.root().text_range())
			new_text: output
		},
	]
}
