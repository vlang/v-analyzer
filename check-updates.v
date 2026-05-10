module main

import cli

fn check_updates_cmd(_ cli.Command) ! {
	download_install_vsh()!
	call_install_vsh('check-updates')!
}
