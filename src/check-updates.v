module main

import cli
import os

fn check_updates_cmd(_ cli.Command) ! {
	if !os.exists(analyzer_dir) {
		os.mkdir(analyzer_dir)!
	}

	download_install_vsh()!
	call_install_vsh('check-updates')!
}
