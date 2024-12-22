module lsp

pub struct CompletionOptions {
pub mut:
	resolve_provider   bool     @[json: resolveProvider]
	trigger_characters []string @[json: triggerCharacters]
}

pub struct CompletionItemSettings {
	snippet_support           bool     @[json: snippetSupport]
	commit_characters_support bool     @[json: commitCharactersSupport]
	preselect_support         bool     @[json: preselectSupport]
	deprecated_support        bool     @[json: deprecatedSupport]
	tag_support               ValueSet @[json: tag_support]
}

// method: ‘textDocument/completion’
// response: []CompletionItem | CompletionList | none
pub struct CompletionParams {
pub:
	// extend: TextDocumentPositionParams
	text_document TextDocumentIdentifier @[json: textDocument]
	position      Position
	context       CompletionContext
}

@[json_as_number]
pub enum CompletionTriggerKind {
	invoked                            = 1
	trigger_character                  = 2
	trigger_for_incomplete_completions = 3
}

pub struct CompletionContext {
pub:
	trigger_kind      CompletionTriggerKind @[json: triggerKind]
	trigger_character string                @[json: triggerCharacter]
}

pub struct CompletionList {
pub:
	is_incomplete bool @[json: isIncomplete]
	items         []CompletionItem
}

@[json_as_number]
pub enum InsertTextFormat {
	plain_text = 1
	snippet    = 2
}

pub struct CompletionItemLabelDetails {
pub:
	// An optional string which is rendered less prominently directly after
	// {@link CompletionItem.label label}, without any spacing. Should be
	// used for function signatures or type annotations.
	detail string @[omitempty]
	// An optional string which is rendered less prominently after
	// {@link CompletionItemLabelDetails.detail}. Should be used for fully qualified
	// names or file path.
	description string
}

pub struct CompletionItem {
pub mut:
	// The label of this completion item.
	//
	// The label property is also by default the text that
	// is inserted when selecting this completion.
	//
	// If label details are provided the label itself should
	// be an unqualified name of the completion item.
	label string
	// Additional details for the label
	label_details CompletionItemLabelDetails @[json: 'labelDetails'; omitempty]
	// The kind of this completion item. Based of the kind
	// an icon is chosen by the editor. The standardized set
	// of available values is defined in `CompletionItemKind`.
	kind CompletionItemKind
	// A human-readable string with additional information
	// about this item, like type or symbol information.
	detail string
	// A human-readable string that represents a doc-comment.
	documentation string
	// A string that should be used when filtering a set of
	// completion items. When `falsy` the label is used.
	filter_text string @[json: 'filterText'; omitempty]
	// A string that should be inserted into a document when selecting
	// this completion. When omitted the label is used as the insert text
	// for this item.
	//
	// The `insertText` is subject to interpretation by the client side.
	// Some tools might not take the string literally. For example
	// VS Code when code complete is requested in this example
	// `con<cursor position>` and a completion item with an `insertText` of
	// `console` is provided it will only insert `sole`. Therefore it is
	// recommended to use `textEdit` instead since it avoids additional client
	// side interpretation.
	insert_text string @[json: 'insertText'; omitempty]
	// The format of the insert text. The format applies to both the
	// `insertText` property and the `newText` property of a provided
	// `textEdit`. If omitted defaults to `InsertTextFormat.PlainText`.
	//
	// Please note that the insertTextFormat doesn't apply to
	// `additionalTextEdits`.
	insert_text_format InsertTextFormat = .plain_text @[json: 'insertTextFormat']
	// How whitespace and indentation is handled during completion
	// item insertion. If not provided the client's default value depends on
	// the `textDocument.completion.insertTextMode` client capability.
	//
	// @since 3.16.0
	// @since 3.17.0 - support for `textDocument.completion.insertTextMode`
	insert_text_mode InsertTextMode @[json: 'insertTextMode'; omitempty]
	// A string that should be used when comparing this item
	// with other items. When omitted the label is used
	// as the sort text for this item.
	sort_text string @[json: 'sortText']
	// text_edit TextEdit @[json:textEdit]
	// additional_text_edits []TextEdit @[json:additionalTextEdits]
	// commit_characters []string @[json:commitCharacters]
	// command Command
	// data string @[raw]
}

@[json_as_number]
pub enum InsertTextMode {
	as_is              = 1
	adjust_indentation = 2
}

@[json_as_number]
pub enum CompletionItemKind {
	text           = 1
	method         = 2
	function       = 3
	constructor    = 4
	field          = 5
	variable       = 6
	class          = 7
	interface_     = 8
	module_        = 9
	property       = 10
	unit           = 11
	value          = 12
	enum_          = 13
	keyword        = 14
	snippet        = 15
	color          = 16
	file           = 17
	reference      = 18
	folder         = 19
	enum_member    = 20
	constant       = 21
	struct_        = 22
	event          = 23
	operator       = 24
	type_parameter = 25
}

pub struct CompletionRegistrationOptions {
	document_selector     []DocumentFilter @[json: documentSelector]
	trigger_characters    []string         @[json: triggerCharacters]
	all_commit_characters []string         @[json: allCommitCharacters]
	resolve_provider      bool             @[json: resolveProvider]
}

// method: ‘completionItem/resolve’
// response: CompletionItem
// request: CompletionItem
