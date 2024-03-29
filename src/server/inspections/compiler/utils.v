module compiler

import os
import lsp
import term
import server.inspections
import analyzer.psi

fn parse_compiler_diagnostic(msg string) ?inspections.Report {
	lines := msg.split_into_lines()
	if lines.len == 0 {
		return none
	}

	mut err_underline := ''
	for line in lines {
		if line.contains('~') {
			err_underline = line
			break
		}
	}
	underline_width := err_underline.count('~')

	first_line := lines.first()

	line_colon_idx := first_line.index_after(':', 2) // deal with `d:/v/...:2:4: error: ...`
	if line_colon_idx < 0 {
		return none
	}
	mut filepath := first_line[..line_colon_idx]
	$if windows {
		filepath = filepath.replace('/', '\\')
	}
	col_colon_idx := first_line.index_after(':', line_colon_idx + 1)
	colon_sep_idx := first_line.index_after(':', col_colon_idx + 1)
	msg_type_colon_idx := first_line.index_after(':', colon_sep_idx + 1)
	if msg_type_colon_idx == -1 || col_colon_idx == -1 || colon_sep_idx == -1 {
		return none
	}

	line_nr := first_line[line_colon_idx + 1..col_colon_idx].int() - 1
	col_nr := first_line[col_colon_idx + 1..colon_sep_idx].int() - 1
	msg_type := first_line[colon_sep_idx + 1..msg_type_colon_idx].trim_space()
	msg_content := first_line[msg_type_colon_idx + 1..].trim_space()

	diag_kind := match msg_type {
		'error' { inspections.ReportKind.error }
		'warning' { inspections.ReportKind.warning }
		'notice' { inspections.ReportKind.notice }
		else { inspections.ReportKind.notice }
	}

	return inspections.Report{
		range: psi.TextRange{
			line: line_nr
			column: col_nr
			end_line: line_nr
			end_column: col_nr + underline_width
		}
		kind: diag_kind
		message: msg_content
		filepath: filepath
	}
}

fn exec_compiler_diagnostics(compiler_path string, uri lsp.DocumentUri) ?[]inspections.Report {
	mut reports := []inspections.Report{}

	dir_path := uri.dir_path()
	filepath := uri.path()
	is_module := !filepath.ends_with('.vv')
	input_path := if is_module { dir_path } else { filepath }

	mut p := os.new_process(compiler_path)
	p.set_args(['-enable-globals', '-shared', '-check', input_path])
	p.set_redirect_stdio()

	defer {
		p.close()
	}
	p.run()
	if p.code == 0 {
		return none
	}

	output_lines := p.stderr_slurp().split_into_lines().map(term.strip_ansi(it))
	errors := split_lines_to_errors(output_lines)

	for error in errors {
		mut report := parse_compiler_diagnostic(error) or { continue }
		file_dir_path := os.dir(report.filepath)

		if os.is_abs_path(file_dir_path) {
			// do nothing
		} else if file_dir_path == '..' {
			report = inspections.Report{
				...report
				filepath: os.join_path_single(dir_path, report.filepath)
			}
		} else if start_idx := dir_path.last_index(file_dir_path) {
			// reported file appears to be in a subdirectory of dir_path
			report = inspections.Report{
				...report
				filepath: dir_path[..start_idx] + report.filepath
			}
		} else {
			// reported file appears to be in a parent directory of dir_path
			report = inspections.Report{
				...report
				filepath: os.join_path_single(dir_path, report.filepath)
			}
		}

		if report.message.contains('unexpected eof') {
			// ignore this error
			continue
		}

		if report.filepath != uri.path() {
			// ignore errors in other files
			continue
		}

		reports << report
	}
	return reports
}

fn split_lines_to_errors(lines []string) []string {
	mut result := []string{}
	mut last_error := ''

	for _, line in lines {
		if line.starts_with(' ') {
			// additional context of an error
			last_error += '\n' + line
		} else {
			if last_error.len > 0 {
				result << last_error
			}
			last_error = line
		}
	}

	if last_error.len > 0 {
		result << last_error
	}

	return result
}
