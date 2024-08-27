module server

import lsp
import runtime
import os
import project
import metadata
import arrays
import config
import loglib
import analyzer.index
import server.protocol
import server.semantic
import server.progress
import server.intentions

// initialize sends the server capabilities to the client
pub fn (mut ls LanguageServer) initialize(params lsp.InitializeParams, mut wr ResponseWriter) lsp.InitializeResult {
	ls.client_pid = params.process_id
	ls.client = protocol.new_client(mut wr)
	ls.progress = progress.new_tracker(mut ls.client)
	ls.bg.start()

	ls.root_uri = params.root_uri
	ls.status = .initialized

	ls.progress.support_work_done_progress = params.capabilities.window.work_done_progress
	ls.initialization_options = params.initialization_options.fields()

	ls.print_info(params.process_id, params.client_info)
	ls.setup()

	ls.register_intention(intentions.AddFlagAttributeIntention{})
	ls.register_intention(intentions.AddHeapAttributeIntention{})
	ls.register_intention(intentions.MakePublicIntention{})

	ls.register_compiler_quick_fix(intentions.MakeMutableQuickFix{})
	ls.register_compiler_quick_fix(intentions.ImportModuleQuickFix{})

	return lsp.InitializeResult{
		capabilities: lsp.ServerCapabilities{
			text_document_sync: lsp.TextDocumentSyncOptions{
				open_close: true
				change:     .full
				will_save:  true
				save:       lsp.SaveOptions{}
			}
			hover_provider:               true
			definition_provider:          true
			type_definition_provider:     true
			references_provider:          lsp.ReferencesOptions{}
			document_formatting_provider: true
			completion_provider:          lsp.CompletionOptions{
				resolve_provider:   false
				trigger_characters: ['.', ':', '(', '@']
			}
			signature_help_provider: lsp.SignatureHelpOptions{
				trigger_characters:   ['(', ',']
				retrigger_characters: [',', ' ']
			}
			code_lens_provider:       lsp.CodeLensOptions{}
			inlay_hint_provider:      lsp.InlayHintOptions{}
			semantic_tokens_provider: lsp.SemanticTokensOptions{
				legend: lsp.SemanticTokensLegend{
					token_types:     semantic.semantic_types
					token_modifiers: semantic.semantic_modifiers
				}
				range: true
				full:  true
			}
			rename_provider: lsp.RenameOptions{
				prepare_provider: false
			}
			document_symbol_provider:    true
			workspace_symbol_provider:   true
			implementation_provider:     true
			document_highlight_provider: true
			code_action_provider:        lsp.CodeActionOptions{
				code_action_kinds: [lsp.quick_fix]
			}
			folding_range_provider:   true
			execute_command_provider: lsp.ExecuteCommandOptions{
				commands: arrays.concat(ls.intentions.values().map(it.id), ...ls.compiler_quick_fixes.values().map(it.id))
			}
		}
		server_info: lsp.ServerInfo{
			name:    metadata.manifest.name
			version: metadata.manifest.version
		}
	}
}

pub fn (mut ls LanguageServer) initialized(mut wr ResponseWriter) {
	loglib.info('-------- New session -------- ')
	if ls.paths.vexe == '' || ls.paths.vlib_root == '' {
		ls.client.send_server_status(health: 'error', quiescent: true)
		return
	} else {
		ls.client.send_server_status(health: 'ok')
	}

	mut work := ls.progress.start('Indexing:', 'roots...', '')

	// Used in tests to avoid indexing the standard library
	need_index_stdlib := 'no-stdlib' !in ls.initialization_options

	if need_index_stdlib {
		ls.indexing_mng.indexer.add_indexing_root(ls.paths.vmodules_root, .modules, ls.paths.cache_dir)
		for path in os.vmodules_paths()[1..] {
			if path.is_blank() {
				continue
			}
			ls.indexing_mng.indexer.add_indexing_root(path, .modules, ls.paths.cache_dir)
		}
		ls.indexing_mng.indexer.add_indexing_root(ls.paths.vlib_root, .standard_library,
			ls.paths.cache_dir)
	}

	if stubs_root := ls.stubs_root() {
		ls.indexing_mng.indexer.add_indexing_root(stubs_root, .stubs, ls.paths.cache_dir)
	}

	ls.indexing_mng.indexer.add_indexing_root(ls.root_uri.path(), .workspace, ls.paths.cache_dir)

	status := ls.indexing_mng.indexer.index(fn [mut work, mut ls] (root index.IndexingRoot, i int) {
		percentage := (i * 70) / ls.indexing_mng.indexer.count_roots()
		work.progress('${i}/${ls.indexing_mng.indexer.count_roots()} (${root.kind.readable_name()})',
			u32(percentage))
		ls.client.log_message('Indexing ${root.root}', .info)
	})

	work.progress('Finish roots indexing', 70)

	if status == .needs_ensure_indexed {
		work.progress('Start ensure indexing', 71)
		ls.indexing_mng.indexer.ensure_indexed()
		work.progress('Finish ensure indexing', 95)
	}

	// Used in tests to avoid indexing the standard library
	need_save_index := 'no-index-save' !in ls.initialization_options

	ls.indexing_mng.indexer.set_no_save(!need_save_index)

	ls.indexing_mng.indexer.save_indexes() or {
		loglib.with_fields({
			'err': err.str()
		}).error('Failed to save index')
	}

	ls.indexing_mng.setup_stub_indexes()

	work.end('Indexing finished')

	ls.client.send_server_status(health: 'ok', quiescent: true)
}

fn (mut ls LanguageServer) setup() {
	ls.setup_config_dir()
	ls.setup_stubs()

	config_path := ls.find_config()
	if config_path == '' {
		ls.client.log_message('No config found', .warning)
		loglib.warn('No config found')
		ls.setup_toolchain()
		ls.setup_vpaths()
		return
	}

	config_content := os.read_file(config_path) or {
		ls.client.log_message('Failed to read config: ${err}', .error)

		loglib.with_fields({
			'err': err.str()
		}).error('Failed to read config')
		return
	}

	cfg := config.from_toml(ls.root_uri.path(), config_path, config_content) or {
		ls.client.log_message('Failed to decode config: ${err}', .error)
		ls.client.log_message('Using default config', .info)

		loglib.with_fields({
			'err': err.str()
		}).error('Failed to decode config')
		loglib.info('Using default config')
		config.EditorConfig{}
	}

	config_type := if cfg.is_local() { 'local' } else { 'global' }
	ls.client.log_message('Using ${config_type} config: ${config_path}', .info)

	ls.cfg = cfg
	if cfg.custom_vroot != '' {
		ls.paths.vroot = os.expand_tilde_to_home(cfg.custom_vroot)

		ls.client.log_message("Find custom VROOT path in '${cfg.path()}' config", .info)
		ls.client.log_message('Using "${cfg.custom_vroot}" as toolchain', .info)

		loglib.info("Find custom VROOT path in '${cfg.path()}' config")
		loglib.info('Using "${cfg.custom_vroot}" as toolchain')
	}

	if cfg.custom_cache_dir != '' {
		ls.paths.cache_dir = os.abs_path(os.expand_tilde_to_home(cfg.custom_cache_dir))

		if !os.exists(ls.paths.cache_dir) {
			os.mkdir_all(ls.paths.cache_dir) or {
				ls.client.log_message('Failed to create custom analyzer caches directory: ${err}',
					.error)

				loglib.with_fields({
					'err': err.str()
				}).error('Failed to create custom analyzer caches directory')
			}
		}

		ls.client.log_message("Find custom cache dir path in '${cfg.path()}' config",
			.info)
		ls.client.log_message('Using "${cfg.custom_cache_dir}" as cache dir', .info)

		loglib.info("Find custom cache dir path in '${cfg.path()}' config")
		loglib.info('Using "${cfg.custom_cache_dir}" as cache dir')
	}

	if ls.paths.vroot == '' {
		// if custom vroot is not set, try to find it
		ls.setup_toolchain()
	}

	if ls.paths.cache_dir == '' {
		ls.setup_cache_dir()
	}

	ls.setup_vpaths()
}

fn (mut ls LanguageServer) setup_cache_dir() {
	if !os.exists(config.analyzer_caches_path) {
		os.mkdir_all(config.analyzer_caches_path) or {
			ls.client.log_message('Failed to create analyzer caches directory: ${err}',
				.error)

			loglib.with_fields({
				'err': err.str()
			}).error('Failed to create analyzer caches directory')
			return
		}
	}

	// if custom cache dir is not set, use default
	ls.paths.cache_dir = config.analyzer_caches_path

	ls.client.log_message('Using "${ls.paths.cache_dir}" as cache dir', .info)
	loglib.info('Using "${ls.paths.cache_dir}" as cache dir')
}

fn (mut ls LanguageServer) find_config() string {
	root := ls.root_uri.path()
	local_config_path := os.join_path(root, '.v-analyzer', 'config.toml')
	if os.exists(local_config_path) {
		return local_config_path
	}

	global_config_path := os.join_path(config.analyzer_configs_path, 'config.toml')
	if os.exists(global_config_path) {
		return global_config_path
	}

	return ''
}

fn (mut ls LanguageServer) setup_toolchain() {
	toolchain_candidates := project.get_toolchain_candidates()
	if toolchain_candidates.len == 0 {
		ls.client.log_message("No toolchain candidates found, some of the features won't work properly.
Please, set `custom_vroot` in local or global config.
Global config path: ${config.analyzer_configs_path}/${config.analyzer_config_name}",
			.error)
		loglib.error("No toolchain candidates found, some of the features won't work properly.
Please, set `custom_vroot` in local or global config.")
		return
	}

	ls.client.log_message('Found toolchain candidates:', .info)
	loglib.info('Found toolchain candidates:')
	for toolchain_candidate in toolchain_candidates {
		ls.client.log_message('  ${toolchain_candidate}', .info)
		loglib.info('  ${toolchain_candidate}')
	}

	ls.client.log_message('Using "${toolchain_candidates.first()}" as toolchain', .info)
	loglib.info('Using "${toolchain_candidates.first()}" as toolchain')
	ls.paths.vroot = toolchain_candidates.first()

	if toolchain_candidates.len > 1 {
		ls.client.log_message('To set other toolchain, use `custom_vroot` in local or global config.
Global config path: ${config.analyzer_configs_path}/${config.analyzer_config_name}',
			.info)
	}
}

fn (mut ls LanguageServer) setup_vpaths() {
	// Prior call of `ls.setup_toolchain()` ensures `ls.paths.vroot` is set.
	vexe_path := os.join_path(ls.paths.vroot, $if windows { 'v.exe' } $else { 'v' })
	if !os.is_file(vexe_path) {
		msg := 'Failed to find V compiler!'
		ls.client.log_message(msg, .error)
		loglib.error(msg)
	} else {
		ls.paths.vexe = vexe_path
		ls.reporter.compiler_path = vexe_path
	}

	vlib_path := os.join_path(ls.paths.vroot, 'vlib')
	if !os.is_dir(vlib_path) {
		msg := 'Failed to find V standard library.'
		ls.client.log_message(msg, .error)
		loglib.error(msg)
	} else {
		ls.paths.vlib_root = vlib_path
	}

	vmodules_root := os.vmodules_dir()
	if !os.is_dir(vmodules_root) {
		msg := 'Failed to find vmodules path.'
		ls.client.log_message(msg, .error)
		loglib.error(msg)
	} else {
		ls.paths.vmodules_root = vmodules_root
		msg := 'Using "${vmodules_root}" as vmodules root.'
		ls.client.log_message(msg, .info)
		loglib.info(msg)
	}
}

fn (mut ls LanguageServer) setup_config_dir() {
	if !os.exists(config.analyzer_configs_path) {
		os.mkdir_all(config.analyzer_configs_path) or {
			ls.client.log_message('Failed to create analyzer configs directory: ${err}',
				.error)

			loglib.with_fields({
				'err': err.str()
			}).error('Failed to create analyzer configs directory')
			return
		}
	}

	if !os.exists(config.analyzer_global_config_path) {
		ls.client.log_message('Global config not found', .info)
		ls.client.log_message('Creating default global analyzer config', .info)

		loglib.info('Global config not found')
		loglib.info('Creating default global analyzer config')

		os.write_file(config.analyzer_global_config_path, config.default) or {
			ls.client.log_message('Failed to create global default analyzer config: ${err}',
				.error)

			loglib.with_fields({
				'err': err.str()
			}).error('Failed to create global default analyzer config')
			return
		}

		ls.client.log_message('Default analyzer config created at ${config.analyzer_global_config_path}',
			.info)
		loglib.info('Default analyzer config created at ${config.analyzer_global_config_path}')
	}
}

fn (mut ls LanguageServer) setup_stubs() {
	if os.exists(config.analyzer_stubs_path) {
		if os.exists(config.analyzer_stubs_version_path) {
			version_string := os.read_file(config.analyzer_stubs_version_path) or {
				ls.client.log_message('Failed to read stubs version: ${err}', .error)

				loglib.with_fields({
					'err': err.str()
				}).error('Failed to read stubs version')
				'0'
			}
			version := version_string.int()

			if version == ls.stubs_version {
				return
			}
		}

		ls.client.log_message('Stubs version mismatch, unpacking new stubs', .info)
		loglib.info('Stubs version mismatch, unpacking new stubs')

		os.rmdir_all(config.analyzer_stubs_path) or {
			ls.client.log_message('Failed to remove old stubs: ${err}', .error)

			loglib.with_fields({
				'err': err.str()
			}).error('Failed to remove old stubs')
		}
	}

	stubs := metadata.embed_fs()
	stubs.unpack_to(config.analyzer_stubs_path) or {
		ls.client.log_message('Failed to unpack stubs: ${err}', .error)

		loglib.with_fields({
			'err': err.str()
		}).error('Failed to unpack stubs')
	}

	os.write_file(config.analyzer_stubs_version_path, ls.stubs_version.str()) or {
		ls.client.log_message('Failed to write stubs version: ${err}', .error)

		loglib.with_fields({
			'err': err.str()
		}).error('Failed to write stubs version')
	}
}

// shutdown sets the state to shutdown but does not exit
@[noreturn]
pub fn (mut ls LanguageServer) shutdown() {
	ls.bg.stop()
	ls.status = .shutdown
	ls.exit()
}

// exit stops the process
@[noreturn]
pub fn (mut ls LanguageServer) exit() {
	// move exit to shutdown for now
	// == .shutdown => 0
	// != .shutdown => 1
	ecode := int(ls.status != .shutdown)
	loglib.info('v-analyzer exiting with ${ls.status}, exit code: ${ecode}')
	exit(ecode)
}

fn (mut ls LanguageServer) print_info(process_id int, client_info lsp.ClientInfo) {
	arch := if runtime.is_64bit() { 64 } else { 32 }
	client_name := if client_info.name.len != 0 {
		'${client_info.name} ${client_info.version}'
	} else {
		'Unknown'
	}
	ls.client.log_message('v-analyzer version: ${metadata.manifest.version}, commit: ${metadata.build_commit}, OS: ${os.user_os()} x${arch}',
		.info)
	ls.client.log_message('v-analyzer executable path: ${os.executable()}', .info)
	ls.client.log_message('v-analyzer build with V ${@VHASH}', .info)
	ls.client.log_message('v-analyzer build at ${metadata.build_datetime}', .info)
	ls.client.log_message('Client / Editor: ${client_name} (PID: ${process_id})', .info)

	loglib.with_fields({
		'client_name':  client_name
		'process_id':   process_id.str()
		'os':           os.user_os()
		'arch':         'x${arch}'
		'executable':   os.executable()
		'build_with':   @VHASH
		'build_at':     metadata.build_datetime
		'build_commit': metadata.build_commit
	}).info('v-analyzer started')
}
