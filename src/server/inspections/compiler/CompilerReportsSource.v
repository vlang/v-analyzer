module compiler

import lsp
import server.inspections

pub struct CompilerReportsSource {
	compiler_path string
}

pub fn (mut c CompilerReportsSource) process(uri lsp.DocumentUri) []inspections.Report {
	reports := exec_compiler_diagnostics(c.compiler_path, uri) or { return [] }
	return reports
}
