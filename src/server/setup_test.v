module server

import os

fn test_setup_vpaths() {
	mut ls := LanguageServer{}
	ls.setup()
	assert ls.paths.vexe == @VEXE
	assert ls.paths.vroot == os.dir(ls.paths.vexe)
	assert ls.paths.vmodules_root == os.vmodules_dir()
	assert ls.paths.vlib_root == os.join_path(ls.paths.vroot, 'vlib')
}
