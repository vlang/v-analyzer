module parser

import tree_sitter_v.bindings
import os

// ParseResult represents the result of a parsing operation.
pub struct ParseResult {
pub:
	tree        &bindings.Tree[bindings.NodeType] = unsafe { nil } // Resulting tree or nil if the source could not be parsed.
	source_text string // Source code.
pub mut:
	path string // Path of the file that was parsed.
}

// Source represent the possible types of V source code to parse.
type Source = []byte | string

// Parser is a wrapper around the Tree-sitter V parser.
pub struct Parser {
mut:
	binding_parser &bindings.Parser[bindings.NodeType] = unsafe { nil }
}

// new creates a new Parser instance.
pub fn Parser.new() &Parser {
	mut bp := bindings.new_parser[bindings.NodeType](bindings.type_factory)
	bp.set_language(bindings.language)
	return &Parser{
		binding_parser: bp
	}
}

// free frees the Tree-sitter parser.
pub fn (p &Parser) free() {
	unsafe {
		p.binding_parser.free()
	}
}

// parse_file parses a V source file and returns the corresponding `tree_sitter.Tree` and `Rope`.
// If the file could not be read, an error is returned.
// If the file was read successfully, but could not be parsed, the result
// is a partially AST.
//
// Example:
// ```
// import parser
//
// fn main() {
//  mut p := parser.Parser.new()
//  res := p.parse_file('foo.v') or {
//     eprintln('Error: could not parse file: ${err}')
//     return
//   }
//   println(res.tree)
// }
// ```
pub fn (mut p Parser) parse_file(filename string) !ParseResult {
	content := os.read_file(filename) or { return error('could not read file ${filename}: ${err}') }
	mut res := p.parse_source(content)
	res.path = filename
	return res
}

// parse_source parses a V code and returns the corresponding `tree_sitter.Tree` and `Rope`.
// Unlike `parse_file`, `parse_source` uses the source directly, without reading it from a file.
// See `parser.Source` for the possible types of `source`.
//
// Example:
// ```
// import parser
//
// fn main() {
//   mut p := parser.Parser.new()
//   res := p.parse_source('fn main() { println("Hello, World!") }') or {
//     eprintln('Error: could not parse source: ${err}')
//     return
//   }
//   println(res.tree)
// }
// ```
pub fn (mut p Parser) parse_source(source Source) ParseResult {
	code := match source {
		string {
			source
		}
		[]byte {
			source.str()
		}
	}
	return p.parse_code(code)
}

// parse_code parses a V code and returns the corresponding `tree_sitter.Tree` and `Rope`.
// Unlike `parse_file` and `parse_source`, `parse_code` don't return an error since
// the source is always valid.
pub fn (mut p Parser) parse_code(code string) ParseResult {
	tree := p.binding_parser.parse_string(source: code)
	return ParseResult{
		tree:        tree
		source_text: code
	}
}

// parse_code_with_tree parses a V code and returns the corresponding `tree_sitter.Tree` and `Rope`.
// This tree can be used to reparse the code with a some changes.
// This is useful for incremental parsing.
//
// Unlike `parse_file` and `parse_source`, `parse_code` don't return an error since
// the source is always valid.
//
// Example:
// ```
// import parser
//
// fn main() {
//   mut p := parser.Parser.new()
//   code := 'fn main() { println("Hello, World!") }'
//   res := p.parse_code_with_tree(code, unsafe { nil })
//   println(res.tree)
//   // some changes in code
//   code2 := 'fn foo() { println("Hello, World!") }'
//   res2 = p.parse_code_with_tree(code2, res.tree)
//   println(res2.tree
// }
pub fn (mut p Parser) parse_code_with_tree(code string, old_tree &bindings.Tree[bindings.NodeType]) ParseResult {
	raw_tree := if isnil(old_tree) { unsafe { nil } } else { old_tree.raw_tree }
	tree := p.binding_parser.parse_string(source: code, tree: raw_tree)
	return ParseResult{
		tree:        tree
		source_text: code
	}
}
