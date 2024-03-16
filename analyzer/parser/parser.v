module parser

import tree_sitter_v
import tree_sitter as ts
import os

// ParseResult represents the result of a parsing operation.
pub struct ParseResult {
pub:
	tree        &ts.Tree[ts.NodeType] = unsafe { nil } // Resulting tree or nil if the source could not be parsed.
	source_text string // Source code.
pub mut:
	path string // Path of the file that was parsed.
}

// Source represent the possible types of V source code to parse.
type Source = []byte | string

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
//  res := parser.parse_file('foo.v') or {
//     eprintln('Error: could not parse file: ${err}')
//     return
//   }
//   println(res.tree)
// }
// ```
pub fn parse_file(filename string) !ParseResult {
	mut file := os.read_file(filename) or {
		return error('could not read file ${filename}: ${err}')
	}
	return parse_source(file)
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
//   res := parser.parse_source('fn main() { println("Hello, World!") }') or {
//     eprintln('Error: could not parse source: ${err}')
//     return
//   }
//   println(res.tree)
// }
// ```
pub fn parse_source(source Source) ParseResult {
	code := match source {
		string {
			source
		}
		[]byte {
			source.str()
		}
	}
	return parse_code(code)
}

// parse_code parses a V code and returns the corresponding `tree_sitter.Tree` and `Rope`.
// Unlike `parse_file` and `parse_source`, `parse_code` don't return an error since
// the source is always valid.
pub fn parse_code(code string) ParseResult {
	return parse_code_with_tree(code, unsafe { nil })
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
//   code := 'fn main() { println("Hello, World!") }'
//   res := parser.parse_code_with_tree(code, unsafe { nil })
//   println(res.tree)
//   // some changes in code
//   code2 := 'fn foo() { println("Hello, World!") }'
//   res2 = parser.parse_code_with_tree(code2, res.tree)
//   println(res2.tree
// }
pub fn parse_code_with_tree(code string, old_tree &ts.Tree[ts.NodeType]) ParseResult {
	mut parser := ts.new_parser[ts.NodeType](ts.type_factory)
	parser.set_language(tree_sitter_v.language)
	raw_tree := if isnil(old_tree) { unsafe { nil } } else { old_tree.raw_tree }
	tree := parser.parse_string(source: code, tree: raw_tree)
	return ParseResult{
		tree: tree
		source_text: code
	}
}
