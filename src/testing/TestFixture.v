module testing

import os
import testing.client
import lsp
import jsonrpc
import server
import analyzer

pub const temp_path = os.join_path(os.temp_dir(), 'v-analyzer-test')

struct TestFile {
	path    string
	content []string
	caret   lsp.Position
}

pub fn (t TestFile) uri() lsp.DocumentUri {
	return lsp.document_uri_from_path(t.path)
}

@[heap; noinit]
pub struct Fixture {
mut:
	ls           &server.LanguageServer = unsafe { nil }
	stream       &client.TestStream     = unsafe { nil }
	server       &jsonrpc.Server        = unsafe { nil }
	test_client  client.TestClient
	current_file TestFile

	opened_files []string
}

pub fn new_fixture() &Fixture {
	indexing_mng := analyzer.IndexingManager.new()
	mut ls := server.LanguageServer.new(indexing_mng)

	mut stream := &client.TestStream{}
	mut jsonprc_server := &jsonrpc.Server{
		stream: stream
		handler: ls
	}

	mut test_client := client.TestClient{
		server: jsonprc_server
		stream: stream
	}

	return &Fixture{
		ls: ls
		stream: stream
		server: jsonprc_server
		test_client: test_client
	}
}

pub fn (mut t Fixture) initialize(with_stdlib bool) !lsp.InitializeResult {
	os.mkdir_all(testing.temp_path)!

	mut options := ['no-index-save', 'no-diagnostics']
	if !with_stdlib {
		options << 'no-stdlib'
	}

	result := t.test_client.send[lsp.InitializeParams, lsp.InitializeResult]('initialize',
		lsp.InitializeParams{
		process_id: 75556
		client_info: lsp.ClientInfo{
			name: 'Testing'
			version: '0.0.1'
		}
		root_uri: lsp.document_uri_from_path(testing.temp_path)
		root_path: testing.temp_path
		initialization_options: options.join(' ')
		capabilities: lsp.ClientCapabilities{}
		trace: ''
		workspace_folders: []
	})!

	return result
}

pub fn (mut t Fixture) initialized() ! {
	t.test_client.send[jsonrpc.Null, jsonrpc.Null]('initialized', jsonrpc.Null{})!
}

pub fn (mut t Fixture) configure_by_file(path string) ! {
	rel_path := 'testdata/${path}'
	content := os.read_file(rel_path)!
	prepared_text := content + '\n\n' // add extra lines to make sure the caret is not at the end of the file
	prepared_content := prepared_text.replace('/*caret*/', '')
	abs_path := os.join_path(testing.temp_path, path)
	dir_path := os.dir(abs_path)
	os.mkdir_all(dir_path)!
	os.write_file(abs_path, prepared_content)!

	if t.current_file.path == abs_path {
		t.close_file(t.current_file.path)
	}

	t.current_file = TestFile{
		path: abs_path
		content: prepared_content.split_into_lines()
		caret: t.caret_pos(prepared_text)
	}

	t.send_open_current_file_request()!
}

pub fn (mut t Fixture) configure_by_text(filename string, text string) ! {
	prepared_text := text + '\n\n' // add extra lines to make sure the caret is not at the end of the file
	content := prepared_text.replace('/*caret*/', '')
	abs_path := os.join_path(testing.temp_path, filename)
	abs_path_without_name := os.dir(abs_path)
	os.mkdir_all(abs_path_without_name)!
	os.write_file(abs_path, content)!

	if t.current_file.path == abs_path {
		t.close_file(t.current_file.path)
	}

	t.current_file = TestFile{
		path: abs_path
		content: content.split_into_lines()
		caret: t.caret_pos(prepared_text)
	}

	t.send_open_current_file_request()!
}

fn (mut t Fixture) send_open_current_file_request() ! {
	t.test_client.send[lsp.DidOpenTextDocumentParams, jsonrpc.Null]('textDocument/didOpen',
		lsp.DidOpenTextDocumentParams{
		text_document: lsp.TextDocumentItem{
			uri: lsp.document_uri_from_path(t.current_file.path)
			language_id: 'v'
			version: 1
			text: t.current_file.content.join('\n')
		}
	}) or {}

	t.test_client.send[lsp.DidChangeTextDocumentParams, jsonrpc.Null]('textDocument/didChange',
		lsp.DidChangeTextDocumentParams{
		text_document: lsp.VersionedTextDocumentIdentifier{
			uri: lsp.document_uri_from_path(t.current_file.path)
			version: 1
		}
		content_changes: [
			lsp.TextDocumentContentChangeEvent{
				text: t.current_file.content.join('\n')
			},
		]
	}) or {}

	t.test_client.send[lsp.DidChangeWatchedFilesParams, jsonrpc.Null]('workspace/didChangeWatchedFiles',
		lsp.DidChangeWatchedFilesParams{
		changes: [
			lsp.FileEvent{
				uri: lsp.document_uri_from_path(t.current_file.path)
				typ: lsp.FileChangeType.created
			},
		]
	}) or {}
}

pub fn (mut t Fixture) definition_at_cursor() []lsp.LocationLink {
	return t.definition(t.current_caret_pos())
}

pub fn (mut t Fixture) definition(pos lsp.Position) []lsp.LocationLink {
	links := t.test_client.send[lsp.TextDocumentPositionParams, []lsp.LocationLink]('textDocument/definition',
		lsp.TextDocumentPositionParams{
		text_document: lsp.TextDocumentIdentifier{
			uri: lsp.document_uri_from_path(t.current_file.path)
		}
		position: pos
	}) or { []lsp.LocationLink{} }

	return links
}

pub fn (mut t Fixture) complete_at_cursor() []lsp.CompletionItem {
	return t.complete(t.current_caret_pos())
}

pub fn (mut t Fixture) complete(pos lsp.Position) []lsp.CompletionItem {
	items := t.test_client.send[lsp.CompletionParams, []lsp.CompletionItem]('textDocument/completion',
		lsp.CompletionParams{
		text_document: lsp.TextDocumentIdentifier{
			uri: lsp.document_uri_from_path(t.current_file.path)
		}
		position: pos
		context: lsp.CompletionContext{
			trigger_kind: .invoked
		}
	}) or { []lsp.CompletionItem{} }

	return items
}

pub fn (mut t Fixture) compute_inlay_hints() []lsp.InlayHint {
	hints := t.test_client.send[lsp.InlayHintParams, []lsp.InlayHint]('textDocument/inlayHint',
		lsp.InlayHintParams{
		text_document: lsp.TextDocumentIdentifier{
			uri: lsp.document_uri_from_path(t.current_file.path)
		}
	}) or { []lsp.InlayHint{} }

	return hints
}

pub fn (mut t Fixture) compute_semantic_tokens() lsp.SemanticTokens {
	tokens := t.test_client.send[lsp.SemanticTokensParams, lsp.SemanticTokens]('textDocument/semanticTokens/full',
		lsp.SemanticTokensParams{
		text_document: lsp.TextDocumentIdentifier{
			uri: lsp.document_uri_from_path(t.current_file.path)
		}
	}) or { lsp.SemanticTokens{} }

	return tokens
}

pub fn (mut t Fixture) implementation_at_cursor() []lsp.Location {
	return t.implementation(t.current_caret_pos())
}

pub fn (mut t Fixture) implementation(pos lsp.Position) []lsp.Location {
	links := t.test_client.send[lsp.TextDocumentPositionParams, []lsp.Location]('textDocument/implementation',
		lsp.TextDocumentPositionParams{
		text_document: lsp.TextDocumentIdentifier{
			uri: lsp.document_uri_from_path(t.current_file.path)
		}
		position: pos
	}) or { []lsp.Location{} }

	return links
}

pub fn (mut t Fixture) supers_at_cursor() []lsp.Location {
	return t.supers(t.current_caret_pos())
}

pub fn (mut t Fixture) supers(pos lsp.Position) []lsp.Location {
	return t.implementation(pos)
}

pub fn (mut t Fixture) documentation_at_cursor() ?lsp.Hover {
	return t.documentation(t.current_caret_pos())
}

pub fn (mut t Fixture) documentation(pos lsp.Position) ?lsp.Hover {
	hover := t.test_client.send[lsp.HoverParams, lsp.Hover]('textDocument/hover', lsp.HoverParams{
		text_document: lsp.TextDocumentIdentifier{
			uri: lsp.document_uri_from_path(t.current_file.path)
		}
		position: pos
	}) or { return none }

	return hover
}

pub fn (mut t Fixture) close_file(path string) {
	t.test_client.send[lsp.DidCloseTextDocumentParams, jsonrpc.Null]('textDocument/didClose',
		lsp.DidCloseTextDocumentParams{
		text_document: lsp.TextDocumentIdentifier{
			uri: lsp.document_uri_from_path(path)
		}
	}) or {}
}

pub fn (mut t Fixture) current_file_uri() lsp.DocumentUri {
	return lsp.document_uri_from_path(t.current_file.path)
}

pub fn (mut t Fixture) text_at_range(range lsp.Range) string {
	lines := t.current_file.content
	start := range.start
	end := range.end

	if start.line == end.line {
		return lines[start.line][start.character..end.character]
	}

	mut result := lines[start.line][start.character..]

	for line in lines[start.line + 1..end.line] {
		result += line
	}

	result += lines[end.line][..end.character]

	return result
}

pub fn (mut t Fixture) current_caret_pos() lsp.Position {
	return t.current_file.caret
}

pub fn (mut t Fixture) caret_pos(file string) lsp.Position {
	for index, line in file.split_into_lines() {
		if line.contains('/*caret*/') {
			return lsp.Position{
				line: index
				character: line.index('/*caret*/') or { 0 }
			}
		}
	}

	return lsp.Position{
		line: 0
		character: 0
	}
}
