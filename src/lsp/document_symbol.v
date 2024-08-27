module lsp

// method: ‘textDocument/documentSymbol’
// response: []DocumentSymbol | []SymbolInformation | none
pub struct DocumentSymbolParams {
pub:
	text_document TextDocumentIdentifier @[json: textDocument]
}

@[json_as_number]
pub enum SymbolKind {
	file           = 1
	module_        = 2
	namespace      = 3
	package        = 4
	class          = 5
	method         = 6
	property       = 7
	field          = 8
	constructor    = 9
	enum_          = 10
	interface_     = 11
	function       = 12
	variable       = 13
	constant       = 14
	string         = 15
	number         = 16
	boolean        = 17
	array          = 18
	object         = 19
	key            = 20
	null           = 21
	enum_member    = 22
	struct_        = 23
	event          = 24
	operator       = 25
	type_parameter = 26
}

pub struct DocumentSymbol {
pub mut:
	// The name of this symbol. Will be displayed in the user interface and
	// therefore must not be an empty string or a string only consisting of
	// white spaces.
	name string
	//  More detail for this symbol, e.g the signature of a function.
	detail     string @[omitempty]
	kind       SymbolKind
	deprecated bool @[omitempty]
	// The range enclosing this symbol not including leading/trailing whitespace
	// but everything else like comments. This information is typically used to
	// determine if the clients cursor is inside the symbol to reveal in the
	// symbol in the UI.
	range Range
	// The range that should be selected and revealed when this symbol is being
	// picked, e.g. the name of a function. Must be contained by the `range`.
	selection_range Range @[json: 'selectionRange'; omitempty]
	// Children of this symbol, e.g. properties of a class.
	children []DocumentSymbol @[omitempty]
}
