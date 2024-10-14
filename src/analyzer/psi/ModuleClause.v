module psi

import os

pub struct ModuleClause {
	PsiElementImpl
}

fn (_ &ModuleClause) stub() {}

pub fn (_ &ModuleClause) is_public() bool {
	return true
}

fn (n &ModuleClause) identifier() ?PsiElement {
	return n.find_child_by_type(.identifier)
}

pub fn (n &ModuleClause) identifier_text_range() TextRange {
	if stub := n.get_stub() {
		return stub.identifier_text_range
	}

	identifier := n.identifier() or { return TextRange{} }
	return identifier.text_range()
}

pub fn (n ModuleClause) name() string {
	if stub := n.get_stub() {
		return stub.name
	}

	identifier := n.identifier() or { return '' }
	return identifier.get_text()
}

pub fn module_qualified_name(file &PsiFile, indexing_root string) string {
	module_name := file.module_name() or { '' }
	if module_name in ['main', 'builtin'] {
		return module_name
	}
	if module_name == '' && file.is_test_file() {
		return ''
	}

	mut root_dirs := [indexing_root]

	src_dir := os.join_path(indexing_root, 'src')
	if os.exists(src_dir) {
		root_dirs << src_dir
	}

	containing_dir := os.dir(file.path)

	mut module_names := []string{}

	mut dir := containing_dir
	for dir != '' && dir !in root_dirs {
		module_names << os.file_name(dir)
		dir = os.dir(dir)
	}

	module_names.reverse_in_place()

	if module_names.len == 0 {
		return module_name
	}

	if module_names.first() == 'builtin' {
		module_names = module_names[1..].clone()
	}

	if module_names.len != 0 && module_names.last() == module_name {
		module_names = module_names[..module_names.len - 1].clone()
	}

	if module_names.len >= 2 && module_names[module_names.len - 1] == 'src'
		&& module_names[module_names.len - 2] == module_name
		&& os.is_file(os.join_path(indexing_root, module_names[0..module_names.len - 1].join(os.path_separator), 'v.mod')) {
		module_names = module_names[..module_names.len - 2].clone()
	}

	qualifier := module_names.join('.')
	if qualifier == '' {
		return module_name
	}

	if module_name == '' {
		return qualifier
	}

	return qualifier + '.' + module_name
}
