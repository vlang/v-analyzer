module psi

import arrays

pub struct PrinterVisitor {
mut:
	indent     int
	lines      []string
	text_lines []string
}

fn (mut r PrinterVisitor) visit_element(element PsiElement) {
	if !r.visit_element_impl(element) {
		return
	}
	mut child := element.first_child() or { return }
	r.indent += 1
	for {
		child.accept_mut(mut r)
		child = child.next_sibling() or { break }
	}
	r.indent -= 1
}

fn (mut r PrinterVisitor) visit_element_impl(element PsiElement) bool {
	r.lines << '  '.repeat(r.indent) + '${element.node.type_name}'
	r.text_lines << '${element.get_text()}'
	return true
}

pub fn (r &PrinterVisitor) print() {
	max_line_width := arrays.max(r.lines.map(it.len)) or { 0 }
	for i, line in r.lines {
		text_lines := r.text_lines[i].split_into_lines()
		if text_lines.len == 0 {
			println('<empty>')
		} else if text_lines.len == 1 {
			println(line + ' '.repeat(max_line_width - line.len) + ' | ' + r.text_lines[i])
		} else {
			println(line + ' '.repeat(max_line_width - line.len) + ' | ' + text_lines[0])
			for j in 1 .. text_lines.len {
				println(' '.repeat(max_line_width) + ' | ' + text_lines[j].trim_string_left('  '))
			}
		}
	}
}
