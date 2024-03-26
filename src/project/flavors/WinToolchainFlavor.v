module flavors

import os

pub struct WinToolchainFlavor {}

fn (s &WinToolchainFlavor) get_home_page_candidates() []string {
	mut res := []string{}
	result := os.execute('where v')
	if result.exit_code == 0 {
		res << os.dir(result.output.trim_space())
	}

	program_files := os.getenv('ProgramFiles')
	if !os.exists(program_files) || !os.is_dir(program_files) {
		return res
	}

	if files := os.ls(program_files) {
		res << files
			.filter(os.is_dir)
			.filter(fn (path string) bool {
				name := os.file_name(path).to_lower()
				return name == 'v' || name.starts_with('vlang')
			})
	}
	return res
}

fn (s &WinToolchainFlavor) is_applicable() bool {
	$if windows {
		return true
	}
	return false
}
