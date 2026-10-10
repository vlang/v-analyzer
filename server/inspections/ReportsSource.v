module inspections

import lsp

pub interface ReportsSource {
mut:
	process(uri lsp.DocumentUri) []Report
}
