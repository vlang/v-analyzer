module lsp

pub struct SemanticTokens {
pub:
	// An optional result id. If provided and clients support delta updating
	// the client will include the result id in the next semantic token request.
	// A server can then instead of computing all semantic tokens again simply
	// send a delta.
	result_id string @[json: 'resultID']
	// The actual tokens.
	data []u32
}

pub struct SemanticTokensOptions {
pub:
	// The legend used by the server
	legend SemanticTokensLegend
	// Server supports providing semantic tokens for a specific range
	// of a document.
	range bool @[omitempty]
	// Server supports providing semantic tokens for a full document.
	full bool @[omitempty]
}

pub struct SemanticTokensLegend {
pub:
	// The token types a server uses.
	token_types []string @[json: 'tokenTypes']
	// The token modifiers a server uses.
	token_modifiers []string @[json: 'tokenModifiers']
}

pub struct SemanticTokensParams {
pub:
	// The text document.
	text_document TextDocumentIdentifier @[json: 'textDocument']
}

pub struct SemanticTokensRangeParams {
pub:
	// The text document.
	text_document TextDocumentIdentifier @[json: 'textDocument']
	// The range the semantic tokens are requested for.
	range Range @[omitempty]
}
