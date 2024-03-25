module lsp

// The kind of a code action.
//
// Kinds are a hierarchical list of identifiers separated by `.`,
// e.g. `"refactor.extract.function"`.
//
// The set of kinds is open and client needs to announce the kinds it supports
// to the server during initialization.
pub type CodeActionKind = string

pub struct CodeActionParams {
pub:
	// The document in which the command was invoked.
	text_document TextDocumentIdentifier @[json: 'textDocument']
	// The range for which the command was invoked.
	range Range
	// Context carrying additional information.
	context CodeActionContext
}

// A set of predefined code action kinds.
pub enum CodeActionTriggerKind {
	// Code actions were explicitly requested by the user or by an extension.
	invoked
	// Code actions were requested automatically.
	//
	// This typically happens when current selection in a file changes, but can
	// also be triggered when file content changes.
	automatic
}

// type CodeActionKind string
pub const empty = ''
pub const quick_fix = 'quickfix'
pub const refactor = 'refactor'
pub const refactor_extract = 'refactor.extract'
pub const refactor_inline = 'refactor.inline'
pub const refactor_rewrite = 'refactor.rewrite'
pub const source = 'source'
pub const source_organize_imports = 'source.organizeImports'

// Contains additional diagnostic information about the context in which
// a code action is run.
pub struct CodeActionContext {
pub:
	// An array of diagnostics known on the client side overlapping the range
	// provided to the `textDocument/codeAction` request. They are provided so
	// that the server knows which errors are currently presented to the user
	// for the given range. There is no guarantee that these accurately reflect
	// the error state of the resource. The primary parameter
	// to compute code actions is the provided range.
	diagnostics []Diagnostic
	// Requested kind of actions to return.
	//
	// Actions not of this kind are filtered out by the client before being
	// shown. So servers can omit computing them.
	only []CodeActionKind
	// The reason why code actions were requested
	trigger_kind CodeActionTriggerKind @[json: 'triggerKind']
}

pub struct CodeAction {
pub:
	// A short, human-readable, title for this code action.
	title string
	// The kind of the code action.
	// Used to filter code actions.
	kind CodeActionKind
	// The diagnostics that this code action resolves.
	diagnostics []Diagnostic
	// Marks this as a preferred action. Preferred actions are used by the
	// `auto fix` command and can be targeted by keybindings.
	//
	// A quick fix should be marked preferred if it properly addresses the
	// underlying error. A refactoring should be marked preferred if it is the
	// most reasonable choice of actions to take.
	//
	// @since 3.15.0
	is_preferred bool @[json: 'isPreferred']
	// The workspace edit this code action performs.
	edit WorkspaceEdit
	// A command this code action executes. If a code action
	// provides an edit and a command, first the edit is
	// executed and then the command.
	command Command
	// A data entry field that is preserved on a code action between
	// a `textDocument/codeAction` and a `codeAction/resolve` request.
	//
	// @since 3.16.0
	data string @[raw]
}

pub struct CodeActionOptions {
pub:
	// CodeActionKinds that this server may return.
	//
	// The list of kinds may be generic, such as `CodeActionKind.Refactor`,
	// or the server may list out every specific kind they provide.
	code_action_kinds []string @[json: 'codeActionKinds']
}
