module semantic

// encode encodes an array of semantic tokens into an array of u32s.
// See https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_semanticTokens
// for more information.
pub fn encode(tokens []SemanticToken) []u32 {
	mut result := tokens.clone()

	// By specification, the tokens must be sorted.
	result.sort_with_compare(fn (left &SemanticToken, right &SemanticToken) int {
		if left.line != right.line {
			if left.line < right.line {
				return -1
			}
			if left.line > right.line {
				return 1
			}
		}
		if left.start < right.start {
			return -1
		}

		if left.start > right.start {
			return 1
		}

		return 0
	})

	mut res := []u32{len: result.len * 5}

	mut cur := 0
	mut last := SemanticToken{}
	for tok in result {
		typ := u32(tok.typ)
		if cur == 0 {
			res[cur] = tok.line
		} else {
			res[cur] = tok.line - last.line
		}
		res[cur + 1] = tok.start
		if cur > 0 && res[cur] == 0 {
			res[cur + 1] = tok.start - last.start
		}
		res[cur + 2] = tok.len
		res[cur + 3] = typ
		res[cur + 4] = if 'mutable' in tok.mods {
			u32(0b010000000000)
		} else if 'global' in tok.mods {
			u32(0b0100000000000)
		} else {
			u32(0)
		} // temp hack
		cur += 5
		last = tok
	}

	return res[..cur]
}
