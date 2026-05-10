module flavors

import os

pub struct UserHomeToolchainFlavor {}

fn (s &UserHomeToolchainFlavor) get_home_page_candidates() []string {
	home := os.home_dir()
	files := os.ls(home) or { return [] }
	return files
		.filter(os.is_dir)
		.filter(fn (path string) bool {
			name := os.file_name(path).to_lower()
			return name == 'v' || name == 'vlang'
		})
}

fn (s &UserHomeToolchainFlavor) is_applicable() bool {
	return true
}
