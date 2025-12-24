module server

import json
import jsonrpc
import lsp
import time
import analyzer
import os
import config
import loglib
import server.progress
import server.protocol
import server.intentions
import server.workspace

pub enum ServerStatus {
	off
	initialized
	shutdown
}

pub struct LanguageServer {
pub mut:
	// status is the current status of the server.
	status ServerStatus = .off
	// root_uri is the URI of the workspace root.
	root_uri lsp.DocumentUri
	// client is a wrapper over `jsonrpc.ResponseWriter` that
	// can be used to send notifications and responses to the client.
	client &protocol.Client = unsafe { nil }
	// client_pid is the process ID of this server.
	client_pid int
	writer     &ResponseWriter = unsafe { nil }
	// opened_files describes all open files in the editor.
	//
	// When a file is opened, the `did_open` method is called,
	// which adds the file to `opened_files`.
	//
	// When the file is closed, the `did_close` method is called,
	// which removes the file from `opened_files`.
	opened_files map[lsp.DocumentUri]analyzer.OpenedFile
	paths        struct {
	mut:
		// vmodules_root is the path to the vmodules directory.
		vmodules_root string
		// vroot is the path to the directory of the V compiler.
		vroot string
		// vexe is the path to the V compiler.
		vexe string
		// vlib_root is the path to the directory of the V standard library.
		vlib_root string
		// cache_dir is the path to the directory with the cache.
		cache_dir string
	}
	// stubs_version incremented on each change in stubs
	//
	// See also `LanguageServer.setup_stubs()`
	stubs_version int = 3
	// initialization_options is a list of custom initialization options.
	// Used to pass custom options in tests.
	initialization_options []string
	// cfg describes the editor configuration from `config.toml`.
	cfg config.EditorConfig
	// bg is a background thread that is designed to perform long-running operations,
	// such as file analyze with third-party tools.
	bg BackgroundThread
	// reporter is used to report diagnostics to the client.
	reporter &DiagnosticReporter = &DiagnosticReporter{}
	// intentions is a map of all intentions that are available in the editor.
	// Use `LanguageServer.register_intention()` to register a new intention.
	intentions map[string]intentions.Intention
	// compiler_quick_fixes is a map of all quick fixes for compiler errors
	// that are available in the editor.
	// Use `LanguageServer.register_compiler_quick_fix()` to register a new quick fix.
	compiler_quick_fixes map[string]intentions.CompilerQuickFix
	// progress is used to report progress to the client.
	// For now it is used only to report progress of indexing.
	progress &progress.Tracker = unsafe { nil }
	// indexing_mng is used to manage indexing.
	indexing_mng analyzer.IndexingManager
	// project_resolver is used to resolve the project root for a given file.
	project_resolver &workspace.ProjectResolver = unsafe { nil }
}

pub fn LanguageServer.new(indexing analyzer.IndexingManager) &LanguageServer {
	return &LanguageServer{
		indexing_mng: indexing
		writer:       unsafe { nil } // will be initialized in `initialize`
		client:       unsafe { nil } // will be initialized in `initialize`
		progress:     unsafe { nil } // will be initialized in `initialize`
	}
}

pub fn (mut _ LanguageServer) stubs_root() ?string {
	if !os.exists(config.analyzer_stubs_path) {
		return none
	}
	return config.analyzer_stubs_path
}

pub fn (mut ls LanguageServer) get_file(uri lsp.DocumentUri) ?analyzer.OpenedFile {
	return ls.opened_files[uri] or {
		loglib.with_fields({
			'uri': uri.str()
		}).warn('Cannot find file in opened_files')
		return none
	}
}

pub fn (mut ls LanguageServer) handle_jsonrpc(request &jsonrpc.Request, mut rw jsonrpc.ResponseWriter) ! {
	// initialize writer upon receiving the first request
	if isnil(ls.writer) {
		ls.writer = rw.server.writer(own_buffer: true)
	}

	watch := time.new_stopwatch(auto_start: true)

	mut w := unsafe { &ResponseWriter(rw) }

	// The server will log a send request/notification
	// log based on the the received payload since the spec
	// doesn't indicate a way to log on the client side and
	// notify it to the server.
	//
	// Notification has no ID attached so the server can detect
	// if its a notification or a request payload by checking
	// if the ID is empty.
	match request.method {
		// Note: LSP specification is unclear whether or not
		// a shutdown request is allowed before server init
		// but we'll just put it here since we want to formally
		// shutdown the server after a certain timeout period.
		'shutdown' {
			ls.shutdown()
			return
		}
		'exit' {
			ls.exit()
			return
		}
		else {}
	}
	if ls.status != .initialized {
		if request.method == 'initialize' {
			params := json.decode(lsp.InitializeParams, request.params) or { return err }
			w.write(ls.initialize(params, mut rw))
		} else if ls.status == .shutdown {
			return jsonrpc.invalid_request
		} else {
			return jsonrpc.server_not_initialized
		}

		loglib.with_fields({
			'method':   request.method
			'duration': watch.elapsed().str()
		}).log_one(.info, 'Request finished')
		return
	}
	match request.method {
		// not only requests but also notifications
		'initialized' {
			ls.initialized(mut rw)
		}
		'textDocument/didOpen' {
			params := json.decode(lsp.DidOpenTextDocumentParams, request.params) or { return err }
			ls.did_open(params)
		}
		'textDocument/didSave' {
			params := json.decode(lsp.DidSaveTextDocumentParams, request.params) or { return err }
			ls.did_save(params)
		}
		'textDocument/didChange' {
			params := json.decode(lsp.DidChangeTextDocumentParams, request.params) or { return err }
			ls.did_change(params)
		}
		'textDocument/didClose' {
			params := json.decode(lsp.DidCloseTextDocumentParams, request.params) or { return err }
			ls.did_close(params)
		}
		'textDocument/willSave' {
			// params := json.decode(lsp.WillSaveTextDocumentParams, request.params) or {
			// 	return err
			// }
			// ls.will_save(params)
		}
		'textDocument/formatting' {
			params := json.decode(lsp.DocumentFormattingParams, request.params) or {
				return w.wrap_error(err)
			}
			w.write(ls.formatting(params) or { return w.wrap_error(err) })
		}
		'textDocument/documentSymbol' {
			params := json.decode(lsp.DocumentSymbolParams, request.params) or {
				return w.wrap_error(err)
			}
			w.write(ls.document_symbol(params) or { return w.wrap_error(err) })
		}
		'workspace/symbol' {
			params := json.decode(lsp.WorkspaceSymbolParams, request.params) or {
				return w.wrap_error(err)
			}
			w.write(ls.workspace_symbol(params) or { return w.wrap_error(err) })
		}
		'textDocument/signatureHelp' {
			params := json.decode(lsp.SignatureHelpParams, request.params) or {
				return w.wrap_error(err)
			}
			w.write(ls.signature_help(params) or { return w.wrap_error(err) })
		}
		'textDocument/completion' {
			params := json.decode(lsp.CompletionParams, request.params) or {
				return w.wrap_error(err)
			}
			w.write(ls.completion(params) or { return w.wrap_error(err) })
		}
		'textDocument/hover' {
			params := json.decode(lsp.HoverParams, request.params) or { return w.wrap_error(err) }
			hover_data := ls.hover(params) or {
				w.write_empty()
				return
			}
			w.write(hover_data)
		}
		'textDocument/foldingRange' {
			params := json.decode(lsp.FoldingRangeParams, request.params) or {
				return w.wrap_error(err)
			}
			w.write(ls.folding_range(params) or { return w.wrap_error(err) })
		}
		'textDocument/definition' {
			params := json.decode(lsp.TextDocumentPositionParams, request.params) or {
				return w.wrap_error(err)
			}
			w.write(ls.definition(params) or { return w.wrap_error(err) })
		}
		'textDocument/typeDefinition' {
			params := json.decode(lsp.TextDocumentPositionParams, request.params) or {
				return w.wrap_error(err)
			}
			w.write(ls.type_definition(params) or { return w.wrap_error(err) })
		}
		'textDocument/references' {
			params := json.decode(lsp.ReferenceParams, request.params) or {
				return w.wrap_error(err)
			}
			w.write(ls.references(params))
		}
		'textDocument/implementation' {
			params := json.decode(lsp.TextDocumentPositionParams, request.params) or {
				return w.wrap_error(err)
			}
			w.write(ls.implementation(params) or { return w.wrap_error(err) })
		}
		'workspace/didChangeWatchedFiles' {
			params := json.decode(lsp.DidChangeWatchedFilesParams, request.params) or { return err }
			ls.did_change_watched_files(params)
		}
		'textDocument/codeLens' {
			params := json.decode(lsp.CodeLensParams, request.params) or {
				return w.wrap_error(err)
			}
			w.write(ls.code_lens(params) or { return w.wrap_error(err) })
		}
		'textDocument/inlayHint' {
			params := json.decode(lsp.InlayHintParams, request.params) or {
				return w.wrap_error(err)
			}
			w.write(ls.inlay_hints(params) or { return w.wrap_error(err) })
		}
		'textDocument/prepareRename' {
			params := json.decode(lsp.PrepareRenameParams, request.params) or {
				return w.wrap_error(err)
			}
			w.write(ls.prepare_rename(params) or { return w.wrap_error(err) })
		}
		'textDocument/rename' {
			params := json.decode(lsp.RenameParams, request.params) or { return w.wrap_error(err) }
			w.write(ls.rename(params) or { return w.wrap_error(err) })
		}
		'textDocument/documentLink' {}
		'textDocument/semanticTokens/full' {
			params := json.decode(lsp.SemanticTokensParams, request.params) or {
				return w.wrap_error(err)
			}
			w.write(ls.semantic_tokens(params.text_document, lsp.Range{}) or {
				return w.wrap_error(err)
			})
		}
		'textDocument/semanticTokens/range' {
			params := json.decode(lsp.SemanticTokensRangeParams, request.params) or {
				return w.wrap_error(err)
			}
			w.write(ls.semantic_tokens(params.text_document, params.range) or {
				return w.wrap_error(err)
			})
		}
		'textDocument/documentHighlight' {
			params := json.decode(lsp.TextDocumentPositionParams, request.params) or {
				return w.wrap_error(err)
			}
			w.write(ls.document_highlight(params) or { return w.wrap_error(err) })
		}
		'textDocument/codeAction' {
			params := json.decode(lsp.CodeActionParams, request.params) or {
				return w.wrap_error(err)
			}
			w.write(ls.code_actions(params) or { return w.wrap_error(err) })
		}
		'workspace/executeCommand' {
			params := json.decode(lsp.ExecuteCommandParams, request.params) or {
				return w.wrap_error(err)
			}
			ls.execute_command(params)
		}
		'v-analyzer/viewStubTree' {
			params := json.decode(lsp.TextDocumentIdentifier, request.params) or {
				return w.wrap_error(err)
			}
			w.write(ls.view_stub_tree(params) or { return w.wrap_error(err) })
		}
		'$/cancelRequest' {
			loglib.info('got $/cancelRequest request')
		}
		else {
			loglib.with_fields({
				'method': request.method
				'params': request.params
			}).info('unhandled method call')
		}
	}

	loglib.with_fields({
		'method':   request.method
		'duration': watch.elapsed().str()
	}).log_one(.info, 'Request finished')
}

pub fn (mut ls LanguageServer) register_intention(intention intentions.Intention) {
	ls.intentions[intention.id] = intention
}

pub fn (mut ls LanguageServer) register_compiler_quick_fix(quickfix intentions.CompilerQuickFix) {
	ls.compiler_quick_fixes[quickfix.id] = quickfix
}

// launch_tool launches a tool with the same vroot as the language server
// and returns the process.
//
// Example:
// ```
// p := ls.launch_tool('tool', 'arg1', 'arg2')!
// defer {
//   p.close()
// }
// p.wait()
// ```
pub fn (mut ls LanguageServer) launch_tool(args ...string) !&os.Process {
	mut p := os.new_process(ls.paths.vexe)
	p.set_args(args)
	p.set_redirect_stdio()
	return p
}
