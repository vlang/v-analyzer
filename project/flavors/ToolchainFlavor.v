module flavors

import arrays
import os

pub interface ToolchainFlavor {
	get_home_page_candidates() []string
	is_applicable() bool
}

fn is_valid_toolchain_path(path string) bool {
	return os.is_dir(path) && has_executable(path, 'v') && has_vlib(path)
}

fn has_executable(path string, exe string) bool {
	mut with_exe := os.join_path(path, exe)
	$if windows {
		with_exe += '.exe'
	}

	return os.is_executable(with_exe)
}

fn has_vlib(path string) bool {
	vlib_path := os.join_path(path, 'vlib')
	return os.is_dir(vlib_path)
}

pub fn get_toolchain_candidates() []string {
	mut flavors := []ToolchainFlavor{}
	flavors << VenvToolchainFlavor{}
	$if !windows {
		// On Windows, a symlink to V is not created, so it makes no sense to check this option.
		flavors << SymlinkToolchainFlavor{}
	}
	flavors << SysPathToolchainFlavor{}
	flavors << UserHomeToolchainFlavor{}
	$if macos {
		flavors << MacToolchainFlavor{}
	}
	$if windows {
		flavors << WinToolchainFlavor{}
	}

	return arrays.flatten(flavors
		.filter(it.is_applicable())
		.map(it.get_home_page_candidates()))
		.filter(is_valid_toolchain_path)
}
