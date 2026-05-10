module main

import cli
import os
import config

fn clear_cache_cmd(_ cli.Command) ! {
	global_config_path := config.analyzer_caches_path
	if !os.exists(global_config_path) {
		warnln('No global cache found at: ${global_config_path}')
		return
	}

	if !os.is_dir(global_config_path) {
		warnln('Global cache directory is not a directory: ${global_config_path}')
		return
	}

	println('Clearing cache...')
	println('Found global cache at: ${global_config_path}')

	os.rmdir_all(global_config_path) or { errorln('Failed to clear cache: ${err}') }

	successln('Cache cleared')
}
