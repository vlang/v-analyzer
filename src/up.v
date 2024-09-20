module main

import cli
import term

fn up_cmd(cmd cli.Command) ! {
	download_install_vsh()!

	is_nightly := cmd.flags.get_bool('nightly') or { false }
	nightly_flag := if is_nightly { '--nightly' } else { '' }

	command := 'up ${nightly_flag}'
	exit_code := call_install_vsh(command)!

	if exit_code != 0 {
		errorln('Failed to update ${term.bold('v-analyzer')}')
		return
	}
}
