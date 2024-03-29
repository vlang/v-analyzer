@[translated]
module psi

import analyzer.parser
import analyzer.psi.types

__global enum_fields_cache = map[string]int{}

pub struct EnumFieldDeclaration {
	PsiElementImpl
}

pub fn (_ &EnumFieldDeclaration) is_public() bool {
	return true
}

pub fn (f &EnumFieldDeclaration) doc_comment() string {
	if stub := f.get_stub() {
		return stub.comment
	}

	if comment := f.find_child_by_type(.line_comment) {
		return comment.get_text().trim_string_left('//').trim(' \t')
	}

	return extract_doc_comment(f)
}

pub fn (f &EnumFieldDeclaration) identifier() ?PsiElement {
	return f.find_child_by_type(.identifier)
}

pub fn (f EnumFieldDeclaration) identifier_text_range() TextRange {
	if stub := f.get_stub() {
		return stub.identifier_text_range
	}

	identifier := f.identifier() or { return TextRange{} }
	return identifier.text_range()
}

pub fn (f &EnumFieldDeclaration) name() string {
	if stub := f.get_stub() {
		return stub.name
	}

	identifier := f.identifier() or { return '' }
	return identifier.get_text()
}

pub fn (f &EnumFieldDeclaration) get_type() types.Type {
	owner := f.owner() or { return types.unknown_type }
	return owner.get_type()
}

pub fn (f &EnumFieldDeclaration) fingerprint() string {
	owner := f.owner() or { return '' }
	return '${f.containing_file.path}:${f.node.start_point()}${owner.name()}.${f.name()}'
}

pub fn (f &EnumFieldDeclaration) value() ?PsiElement {
	if stub := f.get_stub() {
		if stub.additional.len == 0 {
			return none
		}

		res := parser.parse_code(stub.additional)
		root := res.tree.root_node()
		first_child := root.first_child()?
		next_first_child := first_child.first_child()?
		file := new_psi_file(f.containing_file.path, res.tree, res.source_text)
		return create_element(next_first_child, file)
	}

	return f.find_child_by_name('value')
}

pub fn (f &EnumFieldDeclaration) owner() ?&EnumDeclaration {
	if stub := f.get_stub() {
		if parent := stub.parent_of_type(.enum_declaration) {
			if is_valid_stub(parent) {
				if psi := parent.get_psi() {
					if psi is EnumDeclaration {
						return psi
					}
				}
			}
		}
		return none
	}

	psi := f.parent_of_type(.enum_declaration)?
	if psi is EnumDeclaration {
		return psi
	}

	return none
}

pub fn (f &EnumFieldDeclaration) value_presentation(with_dec_value bool) string {
	owner := f.owner() or { return '' }
	count_fields := owner.fields().len
	is_flag := owner.is_flag()

	value := f.get_value()
	if is_flag {
		mut bin := '0b' + f.add_padding('${value:b}', count_fields)
		if with_dec_value {
			bin += ' (${value})'
		}
		return bin
	}

	return value.str()
}

pub fn (f &EnumFieldDeclaration) get_value() i64 {
	fingerprint := f.fingerprint()
	if value := enum_fields_cache[fingerprint] {
		return value
	}

	value := f.get_value_impl()
	enum_fields_cache[fingerprint] = value
	return value
}

fn (f &EnumFieldDeclaration) get_value_impl() i64 {
	owner := f.owner() or { return 0 }
	is_flag := owner.is_flag()

	if !is_flag {
		if value := f.value() {
			if val := f.calculate_value(value) {
				return val
			}
		}
	}

	prev_field := f.prev_sibling_of_type(.enum_field_definition) or {
		return if is_flag { 1 } else { 0 }
	}
	if prev_field is EnumFieldDeclaration {
		prev_value := prev_field.get_value()
		if is_flag {
			return prev_value * 2
		}
		return prev_value + 1
	}
	return 0
}

fn (f &EnumFieldDeclaration) calculate_value(value PsiElement) ?i64 {
	if value is Literal {
		return value.value()
	}

	if value is UnaryExpression {
		if value.operator() == '-' {
			if expr := value.expression() {
				if val := f.calculate_value(expr) {
					return -val
				}
			}
		}
	}

	if value is BinaryExpression {
		operator := value.operator()
		if operator == '<<' {
			left := value.left()?
			right := value.right()?

			left_val := f.calculate_value(left)?
			right_val := f.calculate_value(right)?

			if left_val < 0 {
				// -1 << 1 is prohibited by V
				return none
			}

			return i64(u64(left_val) << right_val)
		}
	}

	return none
}

fn (_ EnumFieldDeclaration) add_padding(value string, size int) string {
	if size == -1 {
		return value
	}

	len := value.len
	if len >= size {
		return value
	}

	return '0'.repeat(size - len) + value
}

pub fn (_ EnumFieldDeclaration) stub() {}
