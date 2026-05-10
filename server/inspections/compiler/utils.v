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

	line_colon_idx := first_line.index_after(':', 2) or { return none } // deal with `d:/v/...:2:4: error: ...`
	mut filepath := first_line[..line_colon_idx]
	$if windows {
		filepath = filepath.replace('/', '\\')
	}
	col_colon_idx := first_line.index_after(':', line_colon_idx + 1) or { return none }
	colon_sep_idx := first_line.index_after(':', col_colon_idx + 1) or { return none }
	msg_type_colon_idx := first_line.index_after(':', colon_sep_idx + 1) or { return none }

	line_nr := first_line[line_colon_idx + 1..col_colon_idx].int() - 1
	col_nr := first_line[col_colon_idx + 1..colon_sep_idx].int() - 1
	msg_type := first_line[colon_sep_idx + 1..msg_type_colon_idx].trim_space()
	msg_content := first_line[msg_type_colon_idx + 1..].trim_space()

	diag_kind := match msg_type {
		'error' { inspections.ReportKind.error }
		'warning' { inspections.ReportKind.warning }
		//'notice' { inspections.ReportKind.notice }
		else { inspections.ReportKind.notice }
	}

	return inspections.Report{
		range:    psi.TextRange{
			line:       line_nr
			column:     col_nr
			end_line:   line_nr
			end_column: col_nr + underline_width
		}
		kind:     diag_kind
		message:  msg_content
		filepath: filepath
	}
}

fn exec_compiler_diagnostics(compiler_path string, uri lsp.DocumentUri, project_root string) ?[]inspections.Report {
	filepath := uri.path()
	is_script := filepath.ends_with('.vsh') || filepath.ends_with('.vv')

	check_target := if is_script { filepath } else { project_root }
	res := os.execute('${compiler_path} -enable-globals -shared -check ${check_target}')

	if res.exit_code == 0 {
		return none
	}

	output_lines := res.output.split_into_lines().map(term.strip_ansi(it))
	errors := split_lines_to_errors(output_lines)

	current_file_abs := os.real_path(filepath)
	mut reports := []inspections.Report{}

	for error in errors {
		report := parse_compiler_diagnostic(error) or { continue }

		// ignore this error
		if report.message.contains('unexpected eof') {
			continue
		}

		report_file_abs := os.real_path(report.filepath)
		if os.to_slash(report_file_abs) != os.to_slash(current_file_abs) {
			continue
		}

		reports << inspections.Report{
			...report
			filepath: filepath
		}
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
