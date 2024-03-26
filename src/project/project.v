module project

import project.flavors
import os

// get_modules_location returns the folder where V looks for and saves modules.
// The default is `~/.vmodules`, however it can be overridden with the `VMODULES` environment variable
pub fn get_modules_location() string {
	return os.vmodules_dir()
}

// get_toolchain_candidates looks for possible places where the V compiler was installed.
// The function returns an array of candidates, where the first element is the highest priority.
// If no candidate is found, then an empty array is returned.
//
// A priority:
// 1. `VROOT` or `VEXE` environment variables
// 2. Symbolic link `/usr/local/bin/v` -> `v` (except Windows)
// 3. Path from `PATH` environment variable
// 4. Other additional search options
pub fn get_toolchain_candidates() []string {
	return distinct_strings(flavors.get_toolchain_candidates())
}

fn distinct_strings(arr []string) []string {
	mut set := map[string]bool{}
	for el in arr {
		set[el] = true
	}
	return set.keys()
}
