module intentions

pub interface CompilerQuickFix {
	Intention
	is_matched_message(msg string) bool
}
