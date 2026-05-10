module main

import cli
import os
import config
import readline
import term

fn init_cmd(cmd cli.Command) ! {
	pwd := os.getwd()
	if pwd == '' {
		return error('Cannot get current working directory')
	}

	directory_for_config := os.join_path(pwd, config.analyzer_local_configs_folder_name)
	if !os.exists(directory_for_config) {
		os.mkdir_all(directory_for_config) or {
			return error("Cannot create '${directory_for_config}' directory for config: ${err}")
		}

		println("${term.green('✓')} Created '${config.analyzer_local_configs_folder_name}' directory for config")
	}

	config_file := os.join_path(directory_for_config, config.analyzer_config_name)
	if os.exists(config_file) {
		warnln("Config file '${config_file}' already exists")
		read_line := readline.read_line('Want to overwrite it? [y/N] ') or {
			errorln('Cannot read line: ${err}')
			'N'
		}
		overwrite := read_line.trim_space() == 'y'
		if !overwrite {
			return
		}
	}

	os.write_file(config_file, config.default) or {
		return error("Cannot write config file '${config_file}': ${err}")
	}

	println("${term.green('✓')} Successfully created config file '${config_file}'")
}
