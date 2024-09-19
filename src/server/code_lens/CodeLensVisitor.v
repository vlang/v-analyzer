module code_lens

import lsp
import config
import json
import server.tform
import analyzer.psi
import analyzer.psi.search

@[noinit]
pub struct CodeLensVisitor {
	cfg             config.CodeLensConfig
	uri             lsp.DocumentUri
	containing_file &psi.PsiFile
	is_test_file    bool
mut:
	run_lens_seen   bool
	first_test_seen bool
	result          []lsp.CodeLens
}

pub fn new_visitor(cfg config.CodeLensConfig, uri lsp.DocumentUri, containing_file &psi.PsiFile) CodeLensVisitor {
	return CodeLensVisitor{
		cfg:             cfg
		uri:             uri
		containing_file: containing_file
		is_test_file:    containing_file.is_test_file()
	}
}

pub fn (mut v CodeLensVisitor) result() []lsp.CodeLens {
	return v.result
}

pub fn (mut v CodeLensVisitor) accept(root psi.PsiElement) {
	for node in psi.new_tree_walker(root.node) {
		v.process_node(node)
	}
}

@[inline]
pub fn (mut v CodeLensVisitor) process_node(node psi.AstNode) {
	if node.type_name == .function_declaration && v.cfg.enable_run_lens {
		v.add_run_lens(node)
	}

	if node.type_name == .function_declaration && v.is_test_file && v.cfg.enable_run_tests_lens {
		v.add_run_test_lens(node)
	}

	if node.type_name == .interface_declaration && v.cfg.enable_inheritors_lens {
		v.add_interface_implementations_lens(node)
	}

	if node.type_name == .struct_declaration && v.cfg.enable_super_interfaces_lens {
		v.add_super_interfaces_lens(node)
	}
}

// add_run_test_lens adds a CodeLens for running the test function or whole file.
pub fn (mut v CodeLensVisitor) add_run_test_lens(node psi.AstNode) {
	name_node := node.child_by_field_name('name') or { return }
	name := name_node.text(v.containing_file.source_text)

	if !name.starts_with('test_') {
		return
	}

	v.add_lens(node, lsp.Command{
		title:     '▶ Run test'
		command:   'v-analyzer.runTests'
		arguments: [
			v.uri.path(),
			name,
		]
	})

	if !v.first_test_seen {
		v.add_lens(node, lsp.Command{
			title:     'all file tests'
			command:   'v-analyzer.runTests'
			arguments: [
				v.uri.path(),
			]
		})
	}

	v.first_test_seen = true
}

// add_run_lens adds a CodeLens for running the main function.
pub fn (mut v CodeLensVisitor) add_run_lens(node psi.AstNode) {
	if v.run_lens_seen {
		// Since in file there can be only one main function, we don't need to process
		// other functions if we already found the main function.
		return
	}

	name := node.child_by_field_name('name') or { return }
	if !name.text_matches(v.containing_file.source_text, 'main') {
		return
	}

	v.add_lens(node, lsp.Command{
		title:     '▶ Run workspace'
		command:   'v-analyzer.runWorkspace'
		arguments: [
			v.uri.path(),
		]
	})
	v.add_lens(node, lsp.Command{
		title:     'single file'
		command:   'v-analyzer.runFile'
		arguments: [
			v.uri.path(),
		]
	})
	v.run_lens_seen = true
}

// add_interface_implementations_lens adds a CodeLens for showing the implementations of an interface.
// If the interface has no implementations, no CodeLens is added.
//
// By clicking on the CodeLens, the user is shown the implementations.
pub fn (mut v CodeLensVisitor) add_interface_implementations_lens(node psi.AstNode) {
	element := psi.create_element(node, v.containing_file)
	if element is psi.InterfaceDeclaration {
		implementations := search.implementations(*element)
		if implementations.len == 0 {
			return
		}

		identifier_text_range := element.identifier_text_range()
		locations := tform.elements_to_locations(implementations)

		lens_title := implementations.len.str() +
			if implementations.len == 1 { ' implementation' } else { ' implementations' }

		v.add_lens(node, lsp.Command{
			title:     lens_title
			command:   'v-analyzer.showReferences'
			arguments: [
				v.uri.path(),
				json.encode(lsp.Position{
					line:      identifier_text_range.line
					character: identifier_text_range.column
				}),
				json.encode(locations),
			]
		})
	}
}

// add_super_interfaces_lens adds a CodeLens for showing the super interfaces of a struct.
// If the struct has no super interfaces, no CodeLens is added.
//
// By clicking on the CodeLens, the user is shown the super interfaces.
pub fn (mut v CodeLensVisitor) add_super_interfaces_lens(node psi.AstNode) {
	element := psi.create_element(node, v.containing_file)
	if element is psi.StructDeclaration {
		supers := search.supers(*element)
		if supers.len == 0 {
			return
		}

		identifier_text_range := element.identifier_text_range()
		locations := tform.elements_to_locations(supers)

		lens_title := 'implement ' + supers.len.str() +
			if supers.len == 1 { ' interface' } else { ' interfaces' }

		v.add_lens(node, lsp.Command{
			title:     lens_title
			command:   'v-analyzer.showReferences'
			arguments: [
				v.uri.path(),
				json.encode(lsp.Position{
					line:      identifier_text_range.line
					character: identifier_text_range.column
				}),
				json.encode(locations),
			]
		})
	}
}

// add_lens adds a new CodeLens with the given command.
pub fn (mut v CodeLensVisitor) add_lens(node psi.AstNode, cmd lsp.Command) {
	start_point := node.start_point()
	start := lsp.Position{
		line:      int(start_point.row)
		character: int(start_point.column)
	}
	v.result << lsp.CodeLens{
		range:   lsp.Range{
			start: start
			end:   start
		}
		command: cmd
	}
}
