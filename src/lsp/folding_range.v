module lsp

type FoldingRangeKind = string

pub struct FoldingRangeKindCapabilities {
pub:
	// The folding range kind values the client supports. When this
	// property exists the client also guarantees that it will
	// handle values outside its set gracefully and falls back
	// to a default value when unknown.
	value_set []FoldingRangeKind @[json: 'valueSet'; omitempty]
}

pub struct FoldingRangeValuesCapabilities {
pub:
	// If set, the client signals that it supports setting collapsedText on
	// folding ranges to display custom labels instead of the default text.
	// @since 3.17.0
	collapsed_text bool @[json: 'collapsedText'; omitempty]
}

pub struct FoldingRangeCapabilities {
pub:
	// The maximum number of folding ranges that the client prefers to receive
	// per document. The value serves as a hint, servers are free to follow the
	// limit.
	range_limit u32 @[json: 'rangeLimit'; omitempty]
	// If set, the client signals that it only supports folding complete lines.
	// If set, client will ignore specified `startCharacter` and `endCharacter`
	// properties in a FoldingRange.
	line_folding_only bool @[json: 'lineFoldingOnly'; omitempty]
	// Specific options for the folding range kind.
	folding_range_kind FoldingRangeKindCapabilities @[json: 'foldingRangeKind'; omitempty]
	// Specific options for the folding range.
	folding_range FoldingRangeValuesCapabilities @[json: 'foldingRange'; omitempty]
}

pub struct FoldingRangeParams {
pub:
	text_document TextDocumentIdentifier @[json: 'textDocument']
}

// Folding range for a comment
pub const folding_range_kind_comment = 'comment'
// Folding range for imports or includes
pub const folding_range_kind_imports = 'imports'
// Folding range for a region (e.g. `#region`)
pub const folding_range_kind_region = 'region'

// Represents a folding range. To be valid, start and end line must be bigger
// than zero and smaller than the number of lines in the document. Clients
// are free to ignore invalid ranges.
pub struct FoldingRange {
pub:
	// The zero-based start line of the range to fold. The folded area starts
	// after the line's last character. To be valid, the end must be zero or
	// larger and smaller than the number of lines in the document.
	start_line int @[json: 'startLine']
	// The zero-based character offset from where the folded range starts. If
	// not defined, defaults to the length of the start line.
	start_character int @[json: 'startCharacter'; omitempty]
	// The zero-based end line of the range to fold. The folded area ends with
	// the line's last character. To be valid, the end must be zero or larger
	// and smaller than the number of lines in the document.
	end_line int @[json: 'endLine']
	// The zero-based character offset before the folded range ends. If not
	// defined, defaults to the length of the end line.
	end_character int @[json: 'endCharacter'; omitempty]
	// Describes the kind of the folding range such as `comment` or `region`.
	// The kind is used to categorize folding ranges and used by commands like
	// 'Fold all comments'. See [FoldingRangeKind](#FoldingRangeKind) for an
	// enumeration of standardized kinds.
	kind string
	// The text that the client should show when the specified range is
	// collapsed. If not defined or not supported by the client, a default
	// will be chosen by the client.
	//
	// @since 3.17.0 - proposed
	collapsed_text string @[json: 'collapsedText'; omitempty]
}
