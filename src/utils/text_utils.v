module utils

pub fn pascal_case_to_snake_case(s string) string {
	mut res := ''
	for index, c in s {
		if c.ascii_str().is_upper() {
			if index > 0 {
				res += '_'
			}
			res += c.ascii_str().to_lower()
		} else {
			res += c.ascii_str()
		}
	}
	return res
}

pub fn snake_case_to_camel_case(s string) string {
	mut res := ''
	mut upper := false
	for c in s {
		if c == `_` {
			upper = true
		} else {
			if upper {
				res += c.ascii_str().to_upper()
				upper = false
			} else {
				res += c.ascii_str()
			}
		}
	}
	return res
}

// compute_offset returns a byte offset from the given position
pub fn compute_offset(src string, line int, col int) int {
	mut offset := 0
	mut src_line := 0
	mut src_col := 0
	src_len := src.len
	for i := 0; i < src_len; i++ {
		byt := src[i]
		is_lf := byt == `\n`
		is_crlf := i + 1 < src_len && byt == `\r` && src[i + 1] == `\n`
		is_eol := is_lf || is_crlf
		if src_line == line && src_col == col {
			return offset
		}
		if is_eol {
			if src_line == line && col > src_col {
				return -1
			}
			src_line++
			src_col = 0
			if is_crlf {
				offset += 2
				i++
			} else {
				offset++
			}
			continue
		}
		src_col++
		offset++
	}
	return offset
}
