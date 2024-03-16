module main

import math
import runtime
import sync
import os
import time
import analyzer.parser
import tree_sitter as ts

fn main() {
	mut checker := Checker{
		root: os.join_path(@VEXEROOT, 'vlib')
	}
	checker.check()
}

pub type AstNode = ts.Node[ts.NodeType]

struct ErrorInfo {
	path string
	node AstNode
}

fn (i ErrorInfo) str() string {
	content := os.read_file(i.path) or { return 'no content' }

	parent := i.node.parent() or { return 'no parent' }
	text := parent.text(content)

	if parent.start_byte() == 0 {
		return 'root'
	}

	return '

Found error at ${i.path}:${i.node.start_point().row}:${i.node.start_point().column}

parent: ${parent}
parent text: ${text}
'
}

struct Checker {
	root string
}

fn (mut _ Checker) need_check(path string) bool {
	if !path.ends_with('.v') {
		return false
	}

	if path.contains('stubs/') {
		return false
	}

	return true
}

pub fn (mut i Checker) check() {
	now := time.now()
	println('Checking root ${i.root}')

	file_chan := chan string{cap: 1000}
	errors_chan := chan []ErrorInfo{cap: 1000}

	spawn fn [mut i, file_chan] () {
		if os.is_file(i.root) {
			file_chan <- i.root
			file_chan.close()
			return
		}

		path := i.root
		os.walk(path, fn [mut i, file_chan] (path string) {
			if i.need_check(path) {
				file_chan <- path
			}
		})

		file_chan.close()
	}()

	spawn i.spawn_checking_workers(errors_chan, file_chan)

	mut processed_files := 0
	mut errors := []ErrorInfo{cap: 100}
	for {
		error := <-errors_chan or { break }
		errors << error
		processed_files++
	}

	mut per_file := map[string]bool{}
	for error in errors {
		per_file[error.path] = true
	}

	println('Checking finished')

	for error in errors[..50] {
		println(error)
	}

	println('Checking took ${time.since(now)}')
	println('\nFound ${errors.len} errors in ${per_file.len} files')
	println('\nParsed correctly ${(100 - (f64(per_file.len) / f64(processed_files) * 100))}% files out of ${processed_files}')
}

pub fn (mut c Checker) check_file(path string) []ErrorInfo {
	content := os.read_file(path) or { return [] }
	res := parser.parse_code(content)

	root := res.tree.root_node()

	errors := c.check_node(path, AstNode(root))

	// unsafe { res.tree.free() }
	return errors
}

pub fn (mut c Checker) check_node(path string, node AstNode) []ErrorInfo {
	mut errors := []ErrorInfo{}
	if node.type_name == .error {
		errors << c.create_error(path, node)
	}

	for i := 0; i < node.child_count(); i++ {
		if child := node.child(u32(i)) {
			errors << c.check_node(path, child)
		}
	}

	return errors
}

pub fn (mut c Checker) create_error(path string, node AstNode) ErrorInfo {
	return ErrorInfo{
		path: path
		node: node
	}
}

pub fn (mut i Checker) spawn_checking_workers(errors_chan chan []ErrorInfo, file_chan chan string) {
	mut wg := sync.new_waitgroup()
	cpus := runtime.nr_cpus()
	workers := math.max(cpus - 1, 1)
	wg.add(workers)
	for j := 0; j < workers; j++ {
		spawn fn [file_chan, mut wg, mut i, errors_chan] () {
			for {
				file := <-file_chan or { break }
				errors_chan <- i.check_file(file)
			}

			wg.done()
		}()
	}

	wg.wait()
	errors_chan.close()
}
