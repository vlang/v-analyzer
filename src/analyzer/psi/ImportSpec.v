module psi

pub struct ImportSpec {
	PsiElementImpl
}

fn (_ &ImportSpec) stub() {}

pub fn (_ &ImportSpec) is_public() bool {
	return true
}

fn (n &ImportSpec) identifier_text_range() TextRange {
	identifier := n.identifier() or { return TextRange{} }
	return identifier.text_range()
}

fn (n &ImportSpec) identifier() ?PsiElement {
	last_part := n.last_part()?
	if last_part is ImportName {
		return last_part
	}
	return none
}

fn (n &ImportSpec) name() string {
	return n.import_name()
}

pub fn (n &ImportSpec) qualified_name() string {
	path := n.path() or { return '' }
	return path.get_text()
}

pub fn (n ImportSpec) alias() ?PsiElement {
	return n.find_child_by_type_or_stub(.import_alias)
}

pub fn (n ImportSpec) path() ?PsiElement {
	return n.find_child_by_type_or_stub(.import_path)
}

pub fn (n ImportSpec) last_part() ?PsiElement {
	path := n.path()?
	return path.last_child_or_stub()
}

pub fn (n ImportSpec) import_name() string {
	if alias := n.alias() {
		if identifier := alias.last_child_or_stub() {
			return identifier.get_text()
		}
	}

	if last_part := n.last_part() {
		return last_part.get_text()
	}

	return ''
}

pub fn (n ImportSpec) alias_name() string {
	if alias := n.alias() {
		if identifier := alias.last_child() {
			return identifier.get_text()
		}
	}

	return ''
}

pub fn (n ImportSpec) resolve_directory() string {
	fqn := n.qualified_name()
	if fqn == '' {
		return ''
	}

	return stubs_index.get_module_root(fqn)
}
