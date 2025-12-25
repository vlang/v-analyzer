module documentation

import analyzer.psi
import strings
import os
import loglib

pub struct Provider {
mut:
	sb strings.Builder = strings.new_builder(100)
}

pub fn (mut p Provider) documentation(element psi.PsiElement) ?string {
	if element is psi.ModuleClause {
		p.module_documentation(element)?
		return p.sb.str()
	}

	if element is psi.FunctionOrMethodDeclaration {
		p.function_documentation(element)?
		return p.sb.str()
	}

	if element is psi.StaticMethodDeclaration {
		p.static_method_documentation(element)?
		return p.sb.str()
	}

	if element is psi.StructDeclaration {
		p.struct_documentation(element)?
		return p.sb.str()
	}

	if element is psi.InterfaceDeclaration {
		p.interface_documentation(element)?
		return p.sb.str()
	}

	if element is psi.InterfaceMethodDeclaration {
		p.interface_method_declaration_documentation(element)?
		return p.sb.str()
	}

	if element is psi.EnumDeclaration {
		p.enum_documentation(element)?
		return p.sb.str()
	}

	if element is psi.ConstantDefinition {
		p.const_documentation(element)?
		return p.sb.str()
	}

	if element is psi.VarDefinition {
		p.variable_documentation(element)?
		return p.sb.str()
	}

	if element is psi.GlobalVarDefinition {
		p.global_variable_documentation(element)?
		return p.sb.str()
	}

	if element is psi.ParameterDeclaration {
		p.parameter_documentation(element)?
		return p.sb.str()
	}

	if element is psi.Receiver {
		p.receiver_documentation(element)?
		return p.sb.str()
	}

	if element is psi.FieldDeclaration {
		p.field_documentation(element)?
		return p.sb.str()
	}

	if element is psi.EmbeddedDefinition {
		p.embedded_definition_documentation(element)?
		return p.sb.str()
	}

	if element is psi.EnumFieldDeclaration {
		p.enum_field_documentation(element)?
		return p.sb.str()
	}

	if element is psi.TypeAliasDeclaration {
		p.type_alias_documentation(element)?
		return p.sb.str()
	}

	if element is psi.ImportSpec {
		p.import_spec_documentation(element)?
		return p.sb.str()
	}

	if element is psi.GenericParameter {
		p.generic_parameter_documentation(element)?
		return p.sb.str()
	}

	return none
}

fn (mut p Provider) import_spec_documentation(element psi.ImportSpec) ? {
	module_fqn := element.qualified_name()

	p.sb.write_string('```v\n')
	p.sb.write_string('module ${module_fqn}')
	p.sb.write_string('\n')
	p.sb.write_string('```')

	dir := element.resolve_directory()
	mut readme_path := os.join_path(dir, 'README.md')
	if !os.exists(readme_path) && os.file_name(dir) == 'src' {
		readme_path = os.join_path(os.dir(dir), 'README.md')
	}
	if os.exists(readme_path) {
		p.write_separator()
		mut content := os.read_file(readme_path) or { return }
		mut lines := content.split_into_lines()
		if lines.len > 0 && lines.first().contains('Description') {
			lines = lines[1..].clone()
			content = lines.join('\n')
		}
		content = content.replace('# ', '### ')
		p.sb.write_string(content)
	}

	p.write_separator()

	p.sb.write_string('---\n')
	p.sb.write_string('```${dir}```\n')
}

fn (mut p Provider) module_documentation(element psi.ModuleClause) ? {
	p.sb.write_string('```v\n')
	p.sb.write_string('module ')
	p.sb.write_string(element.name())
	p.sb.write_string('\n')
	p.sb.write_string('```')
}

fn (mut p Provider) function_documentation(element psi.FunctionOrMethodDeclaration) ? {
	p.write_module_name(element.containing_file)
	signature := element.signature()?
	p.sb.write_string('```v\n')
	if modifiers := element.visibility_modifiers() {
		p.write_visibility_modifiers(modifiers)
		p.sb.write_string(' ')
	}
	p.sb.write_string('fn ')
	if receiver := element.receiver() {
		p.sb.write_string(receiver.get_text())
		p.sb.write_string(' ')
	}
	p.sb.write_string(element.name())
	p.write_generic_parameters(element)
	p.write_signature(signature)
	p.sb.write_string('\n')
	p.sb.write_string('```')
	p.write_separator()
	p.sb.write_string(element.doc_comment())
}

fn (mut p Provider) static_method_documentation(element psi.StaticMethodDeclaration) ? {
	p.write_module_name(element.containing_file)
	signature := element.signature()?
	p.sb.write_string('```v\n')
	if modifiers := element.visibility_modifiers() {
		p.write_visibility_modifiers(modifiers)
		p.sb.write_string(' ')
	}
	p.sb.write_string('fn ')
	if receiver := element.receiver() {
		p.sb.write_string(receiver.get_text())
		p.sb.write_string('.')
	}
	p.sb.write_string(element.name())
	p.write_generic_parameters(element)
	p.write_signature(signature)
	p.sb.write_string('\n')
	p.sb.write_string('```')
	p.write_separator()
	p.sb.write_string(element.doc_comment())
}

fn (mut p Provider) struct_documentation(element psi.StructDeclaration) ? {
	p.write_module_name(element.containing_file)
	p.sb.write_string('```v\n')
	if modifiers := element.visibility_modifiers() {
		p.write_visibility_modifiers(modifiers)
		p.sb.write_string(' ')
	}
	p.sb.write_string('struct ')
	p.sb.write_string(element.name())
	p.write_generic_parameters(element)
	p.sb.write_string('\n')
	p.sb.write_string('```')
	p.write_separator()
	p.sb.write_string(element.doc_comment())
}

fn (mut p Provider) interface_documentation(element psi.InterfaceDeclaration) ? {
	p.write_module_name(element.containing_file)
	p.sb.write_string('```v\n')
	if modifiers := element.visibility_modifiers() {
		p.write_visibility_modifiers(modifiers)
		p.sb.write_string(' ')
	}
	p.sb.write_string('interface ')
	p.sb.write_string(element.name())
	p.write_generic_parameters(element)
	p.sb.write_string('\n')
	p.sb.write_string('```')
	p.write_separator()
	p.sb.write_string(element.doc_comment())
}

fn (mut p Provider) interface_method_declaration_documentation(element psi.InterfaceMethodDeclaration) ? {
	p.write_module_name(element.containing_file)
	signature := element.signature()?
	p.sb.write_string('```v\n')
	p.sb.write_string('pub fn ')

	if owner := element.owner() {
		p.sb.write_string(owner.name())
		p.sb.write_string('.')
	}

	p.sb.write_string(element.name())
	p.write_signature(signature)
	p.sb.write_string('\n')
	p.sb.write_string('```')
	p.write_separator()
	p.sb.write_string(element.doc_comment())
}

fn (mut p Provider) enum_documentation(element psi.EnumDeclaration) ? {
	p.write_module_name(element.containing_file)
	p.sb.write_string('```v\n')
	if modifiers := element.visibility_modifiers() {
		p.write_visibility_modifiers(modifiers)
		p.sb.write_string(' ')
	}
	p.sb.write_string('enum ')
	p.sb.write_string(element.name())
	p.sb.write_string('\n')
	p.sb.write_string('```')
	p.write_separator()
	p.sb.write_string(element.doc_comment())
}

fn (mut p Provider) const_documentation(element psi.ConstantDefinition) ? {
	p.write_module_name(element.containing_file)
	p.sb.write_string('```v\n')
	if modifiers := element.visibility_modifiers() {
		p.write_visibility_modifiers(modifiers)
		p.sb.write_string(' ')
	}
	p.sb.write_string('const ')
	p.sb.write_string(element.name())
	p.sb.write_string(' ')
	p.sb.write_string(element.get_type().readable_name())
	p.sb.write_string(' = ')
	if value := element.expression() {
		p.sb.write_string(value.get_text())
	}
	p.sb.write_string('\n')
	p.sb.write_string('```')
	p.write_separator()
	p.sb.write_string(element.doc_comment())
}

fn (mut p Provider) variable_documentation(element psi.VarDefinition) ? {
	p.sb.write_string('Local **variable**\n')
	p.sb.write_string('```v\n')
	if modifiers := element.mutability_modifiers() {
		p.write_mutability_modifiers(modifiers)
		p.sb.write_string(' ')
	}
	p.sb.write_string(element.name())
	p.sb.write_string(' ')
	p.sb.write_string(element.get_type().readable_name())
	p.sb.write_string('\n')
	p.sb.write_string('```')
}

fn (mut p Provider) global_variable_documentation(element psi.GlobalVarDefinition) ? {
	p.sb.write_string('Global **variable**\n')
	p.sb.write_string('```v\n')
	p.sb.write_string('__global ')
	p.sb.write_string(element.name())
	p.sb.write_string(' ')
	p.sb.write_string(element.get_type().readable_name())
	p.sb.write_string('\n')
	p.sb.write_string('```')
}

fn (mut p Provider) parameter_documentation(element psi.ParameterDeclaration) ? {
	p.sb.write_string('Function **parameter**\n')
	p.sb.write_string('```v\n')
	if modifiers := element.mutability_modifiers() {
		p.write_mutability_modifiers(modifiers)
		p.sb.write_string(' ')
	}
	p.sb.write_string(element.name())
	p.sb.write_string(' ')
	p.sb.write_string(element.get_type().readable_name())
	p.sb.write_string('\n')
	p.sb.write_string('```')
}

fn (mut p Provider) field_documentation(element psi.FieldDeclaration) ? {
	p.sb.write_string('```v\n')

	is_mut, is_pub := element.is_mutable_public()

	if is_pub {
		p.sb.write_string('pub ')
	}
	if is_mut {
		p.sb.write_string('mut ')
	}

	if owner := element.owner() {
		if owner is psi.PsiNamedElement {
			p.sb.write_string(owner.name())
			p.sb.write_string('.')
		}
	}

	p.sb.write_string(element.name())
	p.sb.write_string(' ')
	p.sb.write_string(element.get_type().readable_name())
	p.sb.write_string('\n')
	p.sb.write_string('```')
	p.write_separator()
	p.sb.write_string(element.doc_comment())
}

fn (mut p Provider) embedded_definition_documentation(element psi.EmbeddedDefinition) ? {
	p.sb.write_string('```v\n')
	p.sb.write_string('embedded ')

	if owner := element.owner() {
		if owner is psi.PsiNamedElement {
			p.sb.write_string(owner.name())
			p.sb.write_string('.')
		}
	}

	p.sb.write_string(element.name())
	p.sb.write_string('\n')
	p.sb.write_string('```')
}

fn (mut p Provider) enum_field_documentation(element psi.EnumFieldDeclaration) ? {
	p.sb.write_string('```v\n')
	p.sb.write_string('enum ')

	if owner := element.owner() {
		p.sb.write_string(owner.name())
		p.sb.write_string('.')
	}

	p.sb.write_string(element.name())

	p.sb.write_string(' = ')

	p.sb.write_string(element.value_presentation(true))

	p.sb.write_string('\n')
	p.sb.write_string('```')
	p.write_separator()
	p.sb.write_string(element.doc_comment())
}

fn (mut p Provider) receiver_documentation(element psi.Receiver) ? {
	p.sb.write_string('Method **receiver**\n')
	p.sb.write_string('```v\n')
	if modifiers := element.mutability_modifiers() {
		p.write_mutability_modifiers(modifiers)
		p.sb.write_string(' ')
	}
	p.sb.write_string(element.name())
	p.sb.write_string(' ')
	p.sb.write_string(element.get_type().readable_name())
	p.sb.write_string('\n')
	p.sb.write_string('```')
}

fn (mut p Provider) type_alias_documentation(element psi.TypeAliasDeclaration) ? {
	p.write_module_name(element.containing_file)
	p.sb.write_string('```v\n')
	if modifiers := element.visibility_modifiers() {
		p.write_visibility_modifiers(modifiers)
		p.sb.write_string(' ')
	}
	p.sb.write_string('type ')
	p.sb.write_string(element.name())
	p.write_generic_parameters(element)
	p.sb.write_string(' = ')

	for index, type_ in element.types() {
		p.sb.write_string(psi.convert_type(type_).readable_name())
		if index < element.types().len - 1 {
			p.sb.write_string(' | ')
		}
	}

	p.sb.write_string('\n')
	p.sb.write_string('```')
	p.write_separator()
	p.sb.write_string(element.doc_comment())
}

fn (mut p Provider) generic_parameter_documentation(element psi.GenericParameter) ? {
	p.write_module_name(element.containing_file)
	p.sb.write_string('```v\n')
	p.sb.write_string('generic parameter ')
	p.sb.write_string(element.name())
	p.sb.write_string('\n')
	p.sb.write_string('```')
}

fn (mut p Provider) write_separator() {
	p.sb.write_string('\n\n')
}

fn (mut p Provider) write_signature(signature psi.Signature) {
	p.sb.write_string(signature.get_text())
}

fn (mut p Provider) write_mutability_modifiers(modifiers psi.MutabilityModifiers) {
	p.sb.write_string(modifiers.get_text())
}

fn (mut p Provider) write_visibility_modifiers(modifiers psi.VisibilityModifiers) {
	p.sb.write_string(modifiers.get_text())
}

fn (mut p Provider) write_module_name(file ?&psi.PsiFile) {
	f := file or { return }
	fqn := f.module_fqn()
	name := if fqn.len == 0 {
		f.module_name() or { '' }
	} else {
		fqn
	}

	if name != '' {
		p.sb.write_string('Module: **${name}**\n')
	}
}

fn (mut p Provider) write_generic_parameters(element psi.GenericParametersOwner) {
	parameters := element.generic_parameters() or { return }
	p.sb.write_string(parameters.text_presentation())
}

fn (mut p Provider) write_attributes(element psi.PsiElement) {
	attributes := element.find_child_by_type_or_stub(.attributes) or { return }
	attribute_list := attributes.find_children_by_type_or_stub(.attribute)
	if attribute_list.len == 0 {
		return
	}

	for attr in attribute_list {
		p.sb.write_string(attr.get_text())
		p.sb.write_string('\n')
	}
}

pub fn (mut p Provider) find_documentation_element(element psi.PsiElement) ?psi.PsiElement {
	if element is psi.Identifier {
		parent := element.parent()?
		if parent is psi.ReferenceExpressionBase {
			return parent.resolve() or {
				loglib.with_fields({
					'name': element.get_text()
				}).log(.warn, 'Cannot resolve reference for documentation')
				return element
			}
		}

		if parent is psi.PsiNamedElement {
			return parent as psi.PsiElement
		}

		if parent is psi.ImportName {
			if import_spec := parent.parent_nth(2) {
				if import_spec is psi.ImportSpec {
					return import_spec
				}
			}
		}

		if parent is psi.ImportAlias {
			if import_spec := parent.parent() {
				if import_spec is psi.ImportSpec {
					return import_spec
				}
			}
		}
	}

	return element
}
