module index

fn test_git_files_do_not_need_indexed() {
	mut ir := new_indexing_root('.', .workspace, '/tmp')
	assert !ir.need_index('./.git/some_file.v')
}

fn test_v_test_files_do_not_need_indexed() {
	mut ir := new_indexing_root('.', .workspace, '/tmp')
	assert !ir.need_index('some_file_test.v')
}
