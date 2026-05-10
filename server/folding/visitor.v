module folding

import lsp
import analyzer.psi

pub struct FoldingVisitor {
	source_text string
	lines       []string
mut:
	ranges                []lsp.FoldingRange
	last_comment_end_line int = -2
	comment_start_line    int = -1
}

pub fn FoldingVisitor.new(file &psi.PsiFile) FoldingVisitor {
	return FoldingVisitor{
		source_text: file.source_text
		lines:       file.source_text.split_into_lines()
	}
}

pub fn (mut v FoldingVisitor) accept(root psi.PsiElement) []lsp.FoldingRange {
	mut walker := psi.new_tree_walker(root.node())
	defer { walker.free() }

	for {
		node := walker.next() or { break }
		v.process_node(node)
	}

	v.flush_comment_group()
	return v.ranges
}

fn (mut v FoldingVisitor) process_node(node psi.AstNode) {
	if node.type_name == .line_comment {
		v.process_line_comment(node)
		return
	}
	v.flush_comment_group()

	match node.type_name {
		.block {
			v.fold_block(node)
		}
		.type_initializer {
			if body := node.child_by_field_name('body') {
				v.fold_block(body)
			}
		}
		.struct_declaration, .enum_declaration, .interface_declaration {
			v.fold_delimiters(node, '{', '}', lsp.folding_range_kind_region)
		}
		.global_var_declaration {
			v.fold_delimiters(node, '(', ')', lsp.folding_range_kind_region)
		}
		.import_list {
			v.fold_simple(node, lsp.folding_range_kind_imports)
		}
		.block_comment {
			v.fold_simple(node, lsp.folding_range_kind_comment)
		}
		else {}
	}
}

fn (mut v FoldingVisitor) fold_block(node psi.AstNode) {
	start_line := int(node.start_point().row)
	end_line := int(node.end_point().row)

	if start_line < end_line {
		final_end_line := v.determine_end_line(end_line, '}')
		v.add_range(start_line, final_end_line, lsp.folding_range_kind_region)
	}
}

fn (mut v FoldingVisitor) fold_delimiters(node psi.AstNode, open string, close string, kind string) {
	count := node.child_count()
	mut start_line := -1
	mut end_line := -1

	for i in 0 .. count {
		child := node.child(i) or { continue }
		if child.child_count() > 0 {
			continue
		}

		text := child.text(v.source_text)
		if text == open {
			start_line = int(child.start_point().row)
		} else if text == close {
			end_line = int(child.start_point().row)
		}
	}

	if start_line != -1 && end_line > start_line {
		final_end_line := v.determine_end_line(end_line, close)
		v.add_range(start_line, final_end_line, kind)
	}
}

fn (mut v FoldingVisitor) fold_simple(node psi.AstNode, kind string) {
	start_line := int(node.start_point().row)
	mut end_line := int(node.end_point().row)

	if node.end_point().column == 0 && end_line > start_line {
		end_line--
	}

	for end_line > start_line && end_line < v.lines.len {
		if v.lines[end_line].trim_space() != '' {
			break
		}
		end_line--
	}

	if start_line < end_line {
		v.add_range(start_line, end_line, kind)
	}
}

fn (mut v FoldingVisitor) determine_end_line(end_line int, close string) int {
	if end_line >= v.lines.len {
		return end_line
	}

	line := v.lines[end_line].trim_space()
	if line == close || line == close + ',' || line == close + ';' {
		return end_line
	}
	return end_line - 1
}

@[inline]
fn (mut v FoldingVisitor) add_range(start int, end int, kind string) {
	v.ranges << lsp.FoldingRange{
		start_line: start
		end_line:   end
		kind:       kind
	}
}

fn (mut v FoldingVisitor) process_line_comment(node psi.AstNode) {
	start_line := int(node.start_point().row)
	end_line := int(node.end_point().row)

	if v.last_comment_end_line != -2 && start_line == v.last_comment_end_line + 1 {
		v.last_comment_end_line = end_line
	} else {
		v.flush_comment_group()
		v.comment_start_line = start_line
		v.last_comment_end_line = end_line
	}
}

fn (mut v FoldingVisitor) flush_comment_group() {
	start := v.comment_start_line
	end := v.last_comment_end_line

	v.comment_start_line = -1
	v.last_comment_end_line = -2

	if start != -1 && end > start {
		v.add_range(start, end, lsp.folding_range_kind_comment)
	}
}
