module compiler

import lsp
import server.inspections

pub struct CompilerReportsSource {
pub:
	compiler_path string
}

pub fn (mut c CompilerReportsSource) process(uri lsp.DocumentUri, project_root string) []inspections.Report {
	reports := exec_compiler_diagnostics(c.compiler_path, uri, project_root) or { return [] }
	return reports
}
