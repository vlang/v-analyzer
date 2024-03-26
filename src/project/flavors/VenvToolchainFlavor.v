module flavors

import os

pub struct VenvToolchainFlavor {}

fn (s &VenvToolchainFlavor) get_home_page_candidates() []string {
	mut res := []string{}
	if vroot := os.getenv_opt('VROOT') {
		res << vroot
	}
	if vexe := os.getenv_opt('VEXE') {
		res << os.dir(vexe)
	}
	return res.filter(os.is_dir)
}

fn (s &VenvToolchainFlavor) is_applicable() bool {
	return true
}
