module inspections

import analyzer.psi

pub enum ReportKind {
	error
	warning
	notice
}

pub struct Report {
pub:
	kind     ReportKind
	code     string
	message  string
	filepath string
	source   string
	range    psi.TextRange
}
