module psi

import lsp
import time
import utils
import loglib
import analyzer.parser
import tree_sitter_v.bindings

@[heap]
pub struct PsiFile {
pub:
	path      string
	stub_list &StubList = unsafe { nil }
pub mut:
	tree        &bindings.Tree[bindings.NodeType] = unsafe { nil }
	source_text string
	root        PsiElement
}

pub fn new_psi_file(path string, tree &bindings.Tree[bindings.NodeType], source_text string) &PsiFile {
	mut file := &PsiFile{
		path:        path
		tree:        unsafe { tree }
		source_text: source_text
		stub_list:   unsafe { nil }
		root:        unsafe { nil }
	}
	file.root = create_element(AstNode(tree.root_node()), file)
	return file
}

pub fn new_stub_psi_file(path string, stub_list &StubList) &PsiFile {
	return &PsiFile{
		path:        path
		tree:        unsafe { nil }
		source_text: ''
		stub_list:   stub_list
		root:        unsafe { nil }
	}
}

@[inline]
pub fn (p &PsiFile) is_stub_based() bool {
	return isnil(p.tree)
}

@[inline]
pub fn (p &PsiFile) is_test_file() bool {
	return p.path.ends_with('_test.v')
}

@[inline]
pub fn (p &PsiFile) is_shell_script() bool {
	return p.path.ends_with('.vsh')
}

@[inline]
pub fn (p &PsiFile) index_sink() ?StubIndexSink {
	return stubs_index.get_sink_for_file(p.path)
}

pub fn (mut f PsiFile) reparse(new_code string, mut p parser.Parser) {
	now := time.now()
	unsafe { f.tree.free() }
	// TODO: for some reason if we pass the old tree then trying to get the text
	// of the node gives the text at the wrong offset.
	res := p.parse_code_with_tree(new_code, unsafe { nil })
	f.tree = res.tree
	f.source_text = res.source_text
	f.root = create_element(AstNode(res.tree.root_node()), f)

	loglib.with_duration(time.since(now)).with_fields({
		'file':   f.path
		'length': f.source_text.len.str()
	}).info('Reparsed file')
}

@[inline]
pub fn (p &PsiFile) path() string {
	return p.path
}

@[inline]
pub fn (p &PsiFile) uri() string {
	return lsp.document_uri_from_path(p.path)
}

@[inline]
pub fn (p &PsiFile) text() string {
	return p.source_text
}

pub fn (p &PsiFile) symbol_at(range TextRange) u8 {
	lines := p.source_text.split_into_lines()
	line := lines[range.line] or { return 0 }
	return line[range.column - 1] or { return 0 }
}

pub fn (p &PsiFile) ast_cursor() AstCursor {
	root := p.tree.root_node()
	return AstCursor{
		raw_cursor: root.tree_cursor()
	}
}

pub fn (p &PsiFile) root() PsiElement {
	if p.is_stub_based() {
		return p.stub_list.root().get_psi() or { return p.root }
	}

	return p.root
}

@[inline]
pub fn (p &PsiFile) find_element_at(offset u32) ?PsiElement {
	return p.root.find_element_at(offset)
}

@[inline]
pub fn (p &PsiFile) find_element_at_pos(pos Position) ?PsiElement {
	offset := utils.compute_offset(p.source_text, pos.line, pos.character)
	return p.root.find_element_at(u32(offset))
}

pub fn (p &PsiFile) find_reference_at(offset u32) ?ReferenceExpressionBase {
	element := p.find_element_at(offset)?
	if element is Identifier {
		parent := element.parent()?
		if parent is ReferenceExpressionBase {
			return parent
		}
	}
	if element is ReferenceExpressionBase {
		return element
	}
	return none
}

@[inline]
pub fn (p &PsiFile) module_fqn() string {
	return stubs_index.get_module_qualified_name(p.path)
}

pub fn (p &PsiFile) module_name() ?string {
	module_clause := p.root().find_child_by_type_or_stub(.module_clause)?

	if module_clause is ModuleClause {
		return module_clause.name()
	}

	return none
}

pub fn (p &PsiFile) module_clause() ?&ModuleClause {
	module_clause := p.root().find_child_by_type_or_stub(.module_clause)?

	if module_clause is ModuleClause {
		return module_clause
	}

	return none
}

pub fn (p &PsiFile) get_imports() []ImportSpec {
	mut specs := []ImportSpec{}

	if p.is_stub_based() {
		for _, stub in p.stub_list.index_map {
			if stub.stub_type == .import_spec {
				if element := stub.get_psi() {
					if element is ImportSpec {
						specs << element
					}
				}
			}
		}
	} else {
		mut walker := new_psi_tree_walker(p.root())
		for {
			child := walker.next() or { break }
			if child is ImportSpec {
				specs << child
			}
		}
	}

	return specs
}

pub fn (p &PsiFile) resolve_import_spec(name string) ?ImportSpec {
	imports := p.get_imports()
	if imports.len == 0 {
		return none
	}

	for imp in imports {
		if imp.import_name() == name {
			return imp
		}
	}

	return none
}

pub fn (p &PsiFile) process_declarations(mut processor PsiScopeProcessor) bool {
	children := p.root.children()
	for child in children {
		// if child is PsiNamedElement {
		// 	if !processor.execute(child as PsiElement) {
		// 		return false
		// 	}
		// }
		if child is ConstantDeclaration {
			for constant in child.constants() {
				if constant is PsiNamedElement {
					if !processor.execute(constant as PsiElement) {
						return false
					}
				}
			}
		}
	}

	return true
}

pub fn (p &PsiFile) resolve_selective_import_symbol(name string) ?PsiElement {
	imports := p.get_imports()

	for spec in imports {
		list := spec.selective_list() or { continue }
		symbols := list.symbols()

		for ref in symbols {
			if ref.name() == name {
				if found := p.resolve_symbol_in_import_spec(spec, name) {
					return found
				}
			}
		}
	}

	return none
}

pub fn (p &PsiFile) resolve_symbol_in_import_spec(spec ImportSpec, name string) ?PsiElement {
	import_name := spec.qualified_name()
	real_module_fqn := stubs_index.find_real_module_fqn(import_name)

	if found := p.find_in_module(real_module_fqn, name) {
		return found
	}

	return none
}

fn (p &PsiFile) find_in_module(module_fqn string, name string) ?PsiElement {
	elements := stubs_index.get_all_declarations_from_module(module_fqn, false)
	for element in elements {
		if element is PsiNamedElement {
			if element.name() == name {
				return element as PsiElement
			}
		}
	}

	types := stubs_index.get_all_declarations_from_module(module_fqn, true)
	for type_element in types {
		if type_element is PsiNamedElement {
			if type_element.name() == name {
				return type_element as PsiElement
			}
		}
	}
	return none
}
