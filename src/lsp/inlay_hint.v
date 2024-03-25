module lsp

pub type InlineHintLabel = []InlayHintLabelPart | string
pub type InlineHintTooltip = MarkupContent | string

pub struct InlayHint {
pub:
	// The position of this hint.
	position Position
	// The label of this hint. A human readable string or an array of
	// InlayHintLabelPart label parts.
	//
	// *Note* that neither the string nor the label part can be empty.
	label InlineHintLabel
	// The kind of this hint. Can be omitted in which case the client
	// should fall back to a reasonable default.
	kind InlayHintKind
	// Optional text edits that are performed when accepting this inlay hint.
	//
	// *Note* that edits are expected to change the document so that the inlay
	// hint (or its nearest variant) is now part of the document and the inlay
	// hint itself is now obsolete.
	text_edits []TextEdit @[json: 'textEdits'; omitempty]
	// The tooltip text when you hover over this item.
	tooltip InlineHintTooltip @[json: 'tooltip'; omitempty]
	// Render padding before the hint.
	//
	// Note: Padding should use the editor's background color, not the
	// background color of the hint itself. That means padding can be used
	// to visually align/separate an inlay hint.
	padding_left bool @[json: 'paddingLeft'; omitempty]
	// Render padding after the hint.
	//
	// Note: Padding should use the editor's background color, not the
	// background color of the hint itself. That means padding can be used
	// to visually align/separate an inlay hint.
	padding_right bool @[json: 'paddingRight'; omitempty]
	// A data entry field that is preserved on an inlay hint between
	// a `textDocument/inlayHint` and a `inlayHint/resolve` request.
	data string @[raw]
}

pub struct InlayHintClientCapabilities {
pub:
	// Whether inlay hints support dynamic registration.
	dynamic_registration bool @[json: 'dynamicRegistration']
	// Indicates which properties a client can resolve lazily on an inlay
	// hint.
	resolve_support bool @[json: 'resolveSupport']
}

@[json_as_number]
pub enum InlayHintKind {
	type_
	parameter
}

pub struct InlayHintLabelPart {
pub:
	// The value of this label part.
	value string
	// The tooltip text when you hover over this label part. Depending on
	// the client capability `inlayHint.resolveSupport` clients might resolve
	// this property late using the resolve request.
	tooltip MarkupContent @[omitempty]
	// An optional source code location that represents this
	// label part.
	//
	// The editor will use this location for the hover and for code navigation
	// features: This part will become a clickable link that resolves to the
	// definition of the symbol at the given location (not necessarily the
	// location itself), it shows the hover that shows at the given location,
	// and it shows a context menu with further code navigation commands.
	//
	// Depending on the client capability `inlayHint.resolveSupport` clients
	// might resolve this property late using the resolve request.
	location Location @[omitempty]
	// An optional command for this label part.
	//
	// Depending on the client capability `inlayHint.resolveSupport` clients
	// might resolve this property late using the resolve request.
	command Command @[omitempty]
}

// A parameter literal used in inlay hint requests.
//
// @since 3.17.0
pub struct InlayHintOptions {
pub:
	resolve_provider bool @[json: 'resolveProvider']
}

// A parameter literal used in inlay hint requests.
//
// @since 3.17.0
pub struct InlayHintParams {
pub:
	// The text document.
	text_document TextDocumentIdentifier @[json: 'textDocument']
	// The document range for which inlay hints should be computed.
	range Range
}
