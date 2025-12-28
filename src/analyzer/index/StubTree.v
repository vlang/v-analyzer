module index

import strings
import loglib
import analyzer.psi

// StubTree represents a tree of stubs for a file.
// This tree, unlike the AST, contains the nodes whose data we want to serialize to
// speed up the startup of the server.
// Such nodes implement the `psi.StubBasedPsiElement` interface.
//
// Unlike AST, `StubTree` trees are quite small, so they can be easily saved and fully loaded
// into RAM without taking up a lot of space.
//
// With the help of `StubTree`, stub indexes are also built, which allow us to quickly find
// the necessary elements in the workspace or standard library.
// See `StubbedElementType.index_stub()`.
pub struct StubTree {
	root &psi.StubBase
}

pub fn (tree &StubTree) print() {
	mut sb := strings.new_builder(100)
	mut p := StubTreePrinter{
		sb: &sb
	}
	p.print_stub(tree.root, 0)
	loglib.trace(sb.str())
}

pub fn (tree &StubTree) print_to(mut sb strings.Builder) {
	mut p := StubTreePrinter{
		sb: unsafe { &sb }
	}
	p.print_stub(tree.root, 0)
}

pub fn (tree &StubTree) get_imported_modules() []string {
	mut result := []string{}
	children := tree.root.children_stubs()
	for child in children {
		if child.stub_type() == .import_list {
			declarations := child.children_stubs()
			for declaration in declarations {
				import_spec := declaration.first_child() or { continue }
				import_path := import_spec.first_child() or { continue }
				if import_path.stub_type() == .import_path {
					result << import_path.text()
				}
			}
		}
	}

	return result
}

pub fn build_stub_tree(file &psi.PsiFile, indexing_root string) &StubTree {
	mut cursor := file.ast_cursor()
	defer { cursor.free() }

	stub_root := psi.new_root_stub(file.path())
	module_fqn := psi.module_qualified_name(file, indexing_root)

	if cursor.current_node() != none {
		build_stub_tree_recurse(mut cursor, file, stub_root, module_fqn, false)
	}

	return &StubTree{
		root: stub_root
	}
}

fn build_stub_tree_recurse(mut cursor psi.AstCursor, file &psi.PsiFile, parent &psi.StubBase, module_fqn string, build_for_all_children bool) {
	node := cursor.current_node() or { return }
	node_type := node.type_name

	stub_type := psi.node_type_to_stub_type(node_type)
	is_stubbable := stub_type != .root || psi.node_is_type(node_type)

	mut effective_parent := unsafe { parent }
	mut should_traverse_children := true
	mut pass_down_build_all := false

	if is_stubbable || build_for_all_children {
		psi_element := psi.create_element(node, file)
		element_type := psi.StubbedElementType{}

		if stub := element_type.create_stub(psi_element, parent, module_fqn) {
			effective_parent = unsafe { stub }
			if node_type == .qualified_type {
				pass_down_build_all = true
			}
		}
	}

	if should_traverse_children {
		if cursor.to_first_child() {
			for {
				build_stub_tree_recurse(mut cursor, file, effective_parent, module_fqn,
					build_for_all_children || pass_down_build_all)

				if !cursor.next() {
					break
				}
			}
			cursor.to_parent()
		}
	}
}

struct NodeInfo {
	node   psi.PsiElement
	parent &psi.StubBase
}

pub fn build_stub_tree_iterative(file &psi.PsiFile, mut nodes []NodeInfo) &StubTree {
	root := file.root()
	stub_root := psi.new_root_stub(file.path())

	nodes = nodes[..0].clone()
	nodes << NodeInfo{
		node:   root
		parent: stub_root
	}

	element_type := psi.StubbedElementType{}

	for nodes.len > 0 {
		node := nodes.pop()
		this_parent_stub := node.parent

		parent_stub := if node.node is psi.StubBasedPsiElement {
			if stub := element_type.create_stub(node.node as psi.PsiElement, this_parent_stub,
				'')
			{
				stub
			} else {
				this_parent_stub
			}
		} else {
			this_parent_stub
		}

		for child in node.node.children() {
			nodes << NodeInfo{
				node:   child
				parent: parent_stub
			}
		}
	}
	return &StubTree{
		root: stub_root
	}
}

pub struct StubTreePrinter {
mut:
	sb &strings.Builder
}

pub fn (mut p StubTreePrinter) print_stub(stub psi.StubElement, indent int) {
	for i := 0; i < indent; i++ {
		p.sb.write_string('  ')
	}
	p.sb.write_string(stub.stub_type().str())

	text_range := stub.text_range()
	p.sb.write_string(' at ')
	p.sb.write_string((text_range.line + 1).str())

	text := stub.text()
	if text.len != 0 {
		p.sb.write_string(' ')
		p.sb.write_string('"')
		p.sb.write_string(text)
		p.sb.write_string('"')
	}
	p.sb.write_string('\n')

	for child in stub.children_stubs() {
		p.print_stub(child, indent + 1)
	}
}
