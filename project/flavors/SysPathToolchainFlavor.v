module flavors

import os

pub struct SysPathToolchainFlavor {}

fn (s &SysPathToolchainFlavor) get_home_page_candidates() []string {
	return os.getenv('PATH')
		.split(os.path_delimiter)
		.filter(it != '')
		.filter(os.is_dir)
		.map(if os.file_name(it) == '.bin' {
			os.dir(it)
		} else {
			it
		})
}

fn (s &SysPathToolchainFlavor) is_applicable() bool {
	return true
}
