module psi

// TextRange represents a range of text in a file.
pub struct TextRange {
pub:
	line       int
	column     int
	end_line   int
	end_column int
}

pub fn (t TextRange) == (other TextRange) bool {
	return t.line == other.line && t.column == other.column && t.end_line == other.end_line
		&& t.end_column == other.end_column
}
