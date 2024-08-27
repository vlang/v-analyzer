module lsp

@[json_as_number]
pub enum DiagnosticTag {
	// Unused or unnecessary code.
	//
	// Clients are allowed to render diagnostics with this tag faded out
	// instead of having an error squiggle.
	unnecessary = 1
	// Deprecated or obsolete code.
	//
	// Clients are allowed to rendered diagnostics with this tag strike through.
	deprecated
}

pub struct Diagnostic {
pub mut:
	// The range at which the message applies.
	range Range
	// The diagnostic's severity. Can be omitted. If omitted it is up to the
	// client to interpret diagnostics as error, warning, info or hint.
	severity DiagnosticSeverity
	// The diagnostic's code, which might appear in the user interface.
	code string
	// An optional property to describe the error code.
	code_description string @[json: 'codeDescription']
	// A human-readable string describing the source of this
	// diagnostic, e.g. 'typescript' or 'super lint'.
	source string
	// The diagnostic's message.
	message string
	// Additional metadata about the diagnostic.
	tags []DiagnosticTag @[json: 'tags']
	// An array of related diagnostic information, e.g. when symbol-names within
	// a scope collide all definitions can be marked via this property.
	related_information []DiagnosticRelatedInformation @[json: 'relatedInformation']
	// A data entry field that is preserved between a
	// `textDocument/publishDiagnostics` notification and
	// `textDocument/codeAction` request.
	//
	// @since 3.16.0
	data string @[raw]
}

@[json_as_number]
pub enum DiagnosticSeverity {
	error = 1
	warning
	information
	hint
}

// Represents a related message and source code location for a diagnostic.
// This should be used to point to code locations that cause or are related to
// a diagnostics, e.g when duplicating a symbol in a scope.
pub struct DiagnosticRelatedInformation {
	// The location of this related diagnostic information.
	location Location
	// The message of this related diagnostic information.
	message string
}

// method: ‘textDocument/publishDiagnostics’
pub struct PublishDiagnosticsParams {
pub:
	uri         DocumentUri
	diagnostics []Diagnostic
}
