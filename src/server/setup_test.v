module server

import os
import lsp
import loglib as _ // import to use __global `logger`

const default_vexe = @VEXE
const default_vroot = os.dir(default_vexe)
const default_vlib_root = os.join_path(default_vroot, 'vlib')
const default_vmodules_root = os.vmodules_dir()

fn test_setup_default_vpaths() {
	mut ls := LanguageServer{}
	ls.setup()
	assert ls.paths.vexe == server.default_vexe
	assert ls.paths.vroot == server.default_vroot
	assert ls.paths.vlib_root == server.default_vlib_root
	assert ls.paths.vmodules_root == server.default_vmodules_root
}

fn test_setup_custom_vpaths() {
	mut ls := LanguageServer{}

	custom_root := os.join_path(os.vtmp_dir(), 'v-analyzer-setup-test')
	custom_root_uri := lsp.document_uri_from_path(custom_root)
	cfg_dir_path := os.join_path(custom_root, '.v-analyzer')
	os.mkdir_all(cfg_dir_path)!
	defer {
		os.rmdir_all(cfg_dir_path) or {}
	}

	// Test custom_vroot with missing toolchain ==================================
	mut cfg_toml := 'custom_vroot = "${custom_root}"'
	os.write_file(os.join_path(custom_root, '.v-analyzer', 'config.toml'), cfg_toml)!

	// Set output(io.Writer) for global loglib logger.
	log_file_path := os.join_path(custom_root, 'log')
	os.write_file(log_file_path, '')!
	mut log_file := os.open_append(os.join_path(custom_root, 'log'))!
	logger.out = log_file

	// Run setup
	ls.root_uri = custom_root_uri
	ls.setup()

	log_file.close()
	mut log_out := os.read_file(log_file_path)!
	println('Testlog custom_vroot missing toolchain:')
	println(log_out.trim_space())
	assert log_out.contains('Find custom VROOT path')
	assert log_out.contains('Using "${custom_root}" as toolchain')
	assert log_out.contains('Failed to find standard library path')

	// Test custom_vroot with existing toolchain =================================
	cfg_toml = 'custom_vroot = "${server.default_vroot}"'
	os.write_file(os.join_path(custom_root, '.v-analyzer', 'config.toml'), cfg_toml)!
	os.write_file(log_file_path, '')!
	log_file = os.open_append(os.join_path(custom_root, 'log'))!
	logger.out = log_file
	ls = LanguageServer{}
	ls.root_uri = custom_root_uri

	ls.setup()

	log_file.close()
	log_out = os.read_file(log_file_path)!
	println('Testlog custom_vroot existing toolchain:')
	println(log_out.trim_space())
	assert log_out.contains('Find custom VROOT path')
	assert log_out.contains('Using "${server.default_vroot}" as toolchain')
	assert !log_out.contains('Failed to find standard library path')
}
