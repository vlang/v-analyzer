module documentation

import strings
import analyzer.psi
import analyzer.psi.types

// KeywordProvider unlike `Provider` creates documentation not for named elements i
// but for language keywords.
// This documentation is used to educate users of the language and as an entry point
// to the language documentation.
pub struct KeywordProvider {
mut:
	sb strings.Builder = strings.new_builder(100)
}

pub fn (mut p KeywordProvider) documentation(element psi.PsiElement) ?string {
	text := element.get_text()

	if text == 'chan' {
		p.chan_documentation()
		return p.sb.str()
	}

	return none
}

fn (mut p KeywordProvider) chan_documentation() ? {
	struct_ := psi.find_struct(types.chan_init_type.qualified_name())?
	doc := struct_.doc_comment()
	p.sb.write_string(doc)
}
