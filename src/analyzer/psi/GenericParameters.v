module psi

import strings

pub struct GenericParameters {
	PsiElementImpl
}

fn (_ &GenericParameters) stub() {}

pub fn (n &GenericParameters) parameters() []PsiElement {
	return n.find_children_by_type_or_stub(.generic_parameter)
}

pub fn (n &GenericParameters) text_presentation() string {
	parameters := n.parameters()
	if parameters.len == 0 {
		return ''
	}
	mut sb := strings.new_builder(5)
	sb.write_string('[')
	for index, parameter in parameters {
		if parameter is PsiNamedElement {
			sb.write_string(parameter.name())
		}
		if index < parameters.len - 1 {
			sb.write_string(', ')
		}
	}
	sb.write_string(']')
	return sb.str()
}

pub fn (n &GenericParameters) parameter_names() []string {
	parameters := n.parameters()
	if parameters.len == 0 {
		return []
	}

	mut result := []string{cap: parameters.len}
	for parameter in parameters {
		if parameter is PsiNamedElement {
			result << parameter.name()
		}
	}
	return result
}
