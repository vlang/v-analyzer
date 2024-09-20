module main

import os
import term
import net.http

const download_dir = os.join_path(os.vtmp_dir(), 'v-analyzer')
const analyzer_install_script_download_path = 'https://raw.githubusercontent.com/vlang/v-analyzer/main/install.vsh'
const analyzer_install_script_path = os.join_path(download_dir, 'install.vsh')

pub fn errorln(msg string) {
	eprintln('${term.red('[ERROR]')} ${msg}')
}

pub fn warnln(msg string) {
	println('${term.yellow('[WARN]')} ${msg}')
}

pub fn infoln(msg string) {
	println('${term.blue('[INFO]')} ${msg}')
}

pub fn successln(msg string) {
	println('${term.green('[SUCCESS]')} ${msg}')
}

pub fn download_install_vsh() ! {
	if !os.exists(download_dir) {
		os.mkdir(download_dir) or { return error('Failed to create tmp dir: ${err}') }
	}

	http.download_file(analyzer_install_script_download_path, analyzer_install_script_path) or {
		return error('Failed to download script: ${err}')
	}
}

pub fn call_install_vsh(cmd string) !int {
	$if windows {
		// On Windows we cannot use `os.Command` because it doesn't support Windows
		res := os.execute('v ${analyzer_install_script_path} ${cmd}')
		println(res.output)
		return res.exit_code
	}

	mut command := os.Command{
		path:            'v ${analyzer_install_script_path} ${cmd}'
		redirect_stdout: true
	}

	command.start()!

	for !command.eof {
		println(command.read_line())
	}

	command.close()!

	return command.exit_code
}
