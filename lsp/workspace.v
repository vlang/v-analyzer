module lsp

pub struct WorkspaceFolder {
	uri  DocumentUri
	name string
}

pub type ChangeAnnotationIdentifier = string

// A workspace edit represents changes to many resources managed in the workspace. The edit
// should either provide `changes` or `documentChanges`. If documentChanges are present
// they are preferred over `changes` if the client can handle versioned document edits.
//
// Since version 3.13.0 a workspace edit can contain resource operations as well. If resource
// operations are present clients need to execute the operations in the order in which they
// are provided. So a workspace edit for example can consist of the following two changes:
// (1) a create file a.txt and (2) a text document edit which insert text into file a.txt.
//
// An invalid sequence (e.g. (1) delete file a.txt and (2) insert text into file a.txt) will
// cause failure of the operation. How the client recovers from the failure is described by
// the client capability: `workspace.workspaceEdit.failureHandling`
pub struct WorkspaceEdit {
pub:
	// Holds changes to existing resources.
	changes map[string][]TextEdit @[json: 'changes'; omitempty]
	// Depending on the client capability `workspace.workspaceEdit.resourceOperations` document changes
	// are either an array of `TextDocumentEdit`s to express changes to n different text documents
	// where each text document edit addresses a specific version of a text document. Or it can contain
	// above `TextDocumentEdit`s mixed with create, rename and delete file / folder operations.
	//
	// Whether a client supports versioned document edits is expressed via
	// `workspace.workspaceEdit.documentChanges` client capability.
	//
	// If a client neither supports `documentChanges` nor `workspace.workspaceEdit.resourceOperations` then
	// only plain `TextEdit`s using the `changes` property are supported.
	document_changes []TextDocumentEdit @[json: 'documentChanges'; omitempty]
	// A map of change annotations that can be referenced in `AnnotatedTextEdit`s or create, rename and
	// delete file / folder operations.
	//
	// Whether clients honor this property depends on the client capability `workspace.changeAnnotationSupport`.
	//
	// @since 3.16.0
	change_annotations map[string]ChangeAnnotation @[json: 'changeAnnotations'; omitempty]
}

pub struct ChangeAnnotation { // line 6831
	// A human-readable string describing the actual change. The string
	// is rendered prominent in the user interface.
	label string @[omitempty]
	// A flag which indicates that user confirmation is needed
	// before applying the change.
	needs_confirmation bool @[json: 'needsConfirmation'; omitempty]
	// A human-readable string which is rendered less prominent in
	// the user interface.
	description string @[omitempty]
}

pub struct WorkspaceSymbol {
pub mut:
	// The name of this symbol. Will be displayed in the user interface and
	// therefore must not be an empty string or a string only consisting of
	// white spaces.
	name string
	// The kind of this symbol.
	kind SymbolKind
	// The name of the symbol containing this symbol. This information is for
	// user interface purposes (e.g. to render a qualifier in the user interface
	// if necessary). It can't be used to re-infer a hierarchy for the document
	// symbols.
	container_name string @[json: 'containerName'; omitempty]
	// The location of this symbol. Whether a server is allowed to
	// return a location without a range depends on the client
	// capability `workspace.symbol.resolveSupport`.
	//
	// See also `SymbolInformation.location`.
	location Location @[omitempty]
	// A data entry field that is preserved on a workspace symbol between a
	// workspace symbol request and a workspace symbol resolve request.
	data string @[raw]
}

pub struct DidChangeWorkspaceFoldersParams {
	event WorkspaceFoldersChangeEvent
}

pub struct WorkspaceFoldersChangeEvent {
	added   []WorkspaceFolder
	removed []WorkspaceFolder
}

// method: ‘workspace/didChangeConfiguration’,
// notification
pub struct DidChangeConfigurationParams {
	settings string @[raw]
}

// method: ‘workspace/configuration’
// response: []any / []string
pub struct ConfigurationParams {
	items []ConfigurationItem
}

pub struct ConfigurationItem {
	scope_uri DocumentUri @[json: scopeUri]
	section   string
}

// method: ‘workspace/didChangeWatchedFiles’
// notification
pub struct DidChangeWatchedFilesParams {
pub:
	changes []FileEvent
}

pub struct FileEvent {
pub:
	uri DocumentUri
	typ FileChangeType @[json: 'type']
}

@[json_as_number]
pub enum FileChangeType {
	created = 1
	changed = 2
	deleted = 3
}

pub struct DidChangeWatchedFilesRegistrationOptions {
	watchers []FileSystemWatcher
}

// The  glob pattern to watch.
// Glob patterns can have the following syntax:
// - `*` to match one or more characters in a path segment
// - `?` to match on one character in a path segment
// - `**` to match any number of path segments, including none
// - `{}` to group conditions (e.g. `**​/*.{ts,js}` matches all TypeScript and JavaScript files)
// - `[]` to declare a range of characters to match in a path segment (e.g., `example.[0-9]` to match on `example.0`, `example.1`, …)
// - `[!...]` to negate a range of characters to match in a path segment (e.g., `example.[!0-9]` to match on `example.a`, `example.b`, but not `example.0`)
pub struct FileSystemWatcher {
	glob_pattern string @[json: globPattern]
	kind         int
}

@[json_as_number]
pub enum WatchKind {
	create = 1
	change = 2
	delete = 3
}

// method: ‘workspace/symbol’
// response: []SymbolInformation | null
pub struct WorkspaceSymbolParams {
	query string
}

// method: ‘workspace/executeCommand’
// response: any | null
pub struct ExecuteCommandParams {
pub:
	// The identifier of the actual command handler.
	command string
	// Arguments that the command should be invoked with.
	arguments string @[raw]
}

pub struct ExecuteCommandRegistrationOptions {
	command []string
}

// method: ‘workspace/applyEdit’
// response: ApplyWorkspaceEditResponse
//
pub struct ApplyWorkspaceEditParams {
pub:
	// An optional label of the workspace edit. This label is
	// presented in the user interface for example on an undo
	// stack to undo the workspace edit.
	label string @[omitempty]
	// The edits to apply.
	edit WorkspaceEdit
}

pub struct ApplyWorkspaceEditResponse {
	applied        bool
	failure_reason string @[json: failureReason]
}
