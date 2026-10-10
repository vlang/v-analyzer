module lsp

// TODO: These LSPAny need to change to `?LSPAny` too.
type LSPAny = []LSPAny | map[string]LSPAny | f64 | bool | string

// method: ‘initialize’
// response: InitializeResult
pub struct InitializeParams {
pub mut:
	process_id  int = -2         @[json: processId]
	client_info ClientInfo  @[json: clientInfo]
	root_uri    DocumentUri @[json: rootUri]
	root_path   DocumentUri @[json: rootPath]
	// TODO: Change this to `?LSPAny` once V fixed its JSON decoder codegen. (or shall we use json2?)
	initialization_options LSPAny @[json: initializationOptions]
	capabilities           ClientCapabilities
	trace                  string
	workspace_folders      []WorkspaceFolder @[skip]
}

pub struct ClientInfo {
pub mut:
	name    string @[json: name]
	version string @[json: version]
}

pub struct ServerInfo {
pub mut:
	name    string
	version string
}

pub struct InitializeResult {
pub:
	capabilities ServerCapabilities
	server_info  ServerInfo @[json: 'serverInfo'; omitempty]
}

// method: ‘initialized’
// notification
// pub struct InitializedParams {}

@[json_as_number]
pub enum InitializeErrorCode {
	unknown_protocol_version = 1
}

pub struct InitializeError {
	retry bool
}

/*
*
 * The kind of resource operations supported by the client.
*/

@[json_as_number]
pub enum ResourceOperationKind {
	create
	rename
	delete
}

@[json_as_number]
pub enum FailureHandlingKind {
	abort
	transactional
	undo
	text_only_transactional
}

pub struct ExecuteCommandOptions {
pub:
	// The commands to be executed on the server
	commands []string
}

pub struct StaticRegistrationOptions {
	id string
}

// method: ‘shutdown’
// response: none
// method: ‘exit’
// response: none
