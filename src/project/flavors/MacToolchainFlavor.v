module flavors

import os

pub struct MacToolchainFlavor {}

fn (s &MacToolchainFlavor) get_home_page_candidates() []string {
	return ['/usr/local/Cellar/v', '/usr/local/v', os.expand_tilde_to_home('~/v')]
		.filter(os.is_dir)
}

fn (s &MacToolchainFlavor) is_applicable() bool {
	$if macos {
		return true
	}
	return false
}
