module server

import lsp
import time
import loglib
import server.tform
import server.inspections
import server.inspections.compiler

pub fn (mut ls LanguageServer) run_diagnostics_in_bg(uri lsp.DocumentUri) {
	ls.bg.queue(fn [mut ls, uri] () {
		ls.run_diagnostics(uri)
	})
}

pub fn (mut ls LanguageServer) run_diagnostics(uri lsp.DocumentUri) {
	watch := time.new_stopwatch(auto_start: true)
	ls.reporter.clear(uri)
	ls.reporter.run_all_inspections(uri)
	ls.reporter.publish(mut ls.writer, uri)

	loglib.with_fields({
		'caller':   @METHOD
		'duration': watch.elapsed().str()
	}).info('Updated diagnostics')
}

pub struct DiagnosticReporter {
mut:
	compiler_path string
	reports       map[lsp.DocumentUri][]inspections.Report
}

fn (mut d DiagnosticReporter) run_all_inspections(uri lsp.DocumentUri) {
	mut source := compiler.CompilerReportsSource{
		compiler_path: d.compiler_path
	}
	d.reports[uri] = source.process(uri)
}

fn (mut d DiagnosticReporter) clear(uri lsp.DocumentUri) {
	d.reports[uri] = []
}

fn (mut d DiagnosticReporter) publish(mut wr ResponseWriter, uri lsp.DocumentUri) {
	reports := d.reports[uri] or { return }
	wr.publish_diagnostics(lsp.PublishDiagnosticsParams{
		uri: uri
		diagnostics: reports.map(d.convert_report(it))
	})
}

fn (_ &DiagnosticReporter) convert_report(report inspections.Report) lsp.Diagnostic {
	possibly_unused := report.message.starts_with('unused')
	possibly_deprecated := report.message.contains('deprecated')
	mut tags := []lsp.DiagnosticTag{}
	if possibly_unused {
		tags << lsp.DiagnosticTag.unnecessary
	}
	if possibly_deprecated {
		tags << lsp.DiagnosticTag.deprecated
	}

	return lsp.Diagnostic{
		range: tform.text_range_to_lsp_range(report.range)
		severity: match report.kind {
			.error { lsp.DiagnosticSeverity.error }
			.warning { lsp.DiagnosticSeverity.warning }
			.notice { lsp.DiagnosticSeverity.information }
		}
		source: 'compiler'
		message: report.message
		tags: tags
	}
}

// publish_diagnostics sends errors, warnings and other diagnostics to the editor
fn (mut wr ResponseWriter) publish_diagnostics(params lsp.PublishDiagnosticsParams) {
	wr.write_notify('textDocument/publishDiagnostics', params)
}
