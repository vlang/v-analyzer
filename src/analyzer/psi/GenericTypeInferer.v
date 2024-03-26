module psi

import analyzer.psi.types
import math

struct GenericTypeInferer {}

fn (g &GenericTypeInferer) infer_generic_call(arg_owner GenericArgumentsOwner, params_owner GenericParametersOwner, result_type types.Type) types.Type {
	generic_ts_map := g.infer_generic_ts_map(arg_owner, params_owner)
	return result_type.substitute_generics(generic_ts_map)
}

fn (g &GenericTypeInferer) infer_generic_fetch(resolved PsiElement, expr SelectorExpression, generic_type types.Type) types.Type {
	if resolved !is FieldDeclaration {
		return generic_type
	}

	qualifier := expr.qualifier() or { return generic_type }
	qualifier_type := infer_type(qualifier)
	instantiation := g.extract_instantiation(qualifier_type) or { return generic_type }

	qualifier_specialization_map := g.infer_qualifier_generic_ts_map(instantiation)
	if qualifier_specialization_map.len == 0 {
		return generic_type
	}

	return generic_type.substitute_generics(qualifier_specialization_map)
}

fn (g &GenericTypeInferer) infer_generic_ts_map(arg_owner GenericArgumentsOwner, params_owner GenericParametersOwner) map[string]types.Type {
	if arg_owner is CallExpression {
		if ref_expression := arg_owner.ref_expression() {
			if qualifier := ref_expression.qualifier() {
				qualifier_type := infer_type(qualifier)
				if instantiation := g.extract_instantiation(qualifier_type) {
					qualifier_specialization_map := g.infer_qualifier_generic_ts_map(instantiation)
					return g.infer_simple_generic_ts_map(arg_owner, params_owner, qualifier_specialization_map)
				}
			}
		}
	}

	return g.infer_simple_generic_ts_map(arg_owner, params_owner, map[string]types.Type{})
}

fn (g &GenericTypeInferer) infer_simple_generic_ts_map(arg_owner GenericArgumentsOwner, params_owner GenericParametersOwner, additional map[string]types.Type) map[string]types.Type {
	generic_parameters := g.generics_parameter_names(params_owner)

	// No data for inference, call is not generic.
	if generic_parameters.len == 0 && additional.len == 0 {
		return map[string]types.Type{}
	}

	// foo[int, string]()
	//    ^^^^^^^^^^^^^ explicit generic arguments
	// Array[string]{}
	//      ^^^^^^^^ explicit generic arguments
	if generic_arguments := arg_owner.type_arguments() {
		generic_arguments_types := generic_arguments.types()
		if generic_arguments_types.len > 0 {
			// T: int
			// U: string
			mut mapping := map[string]types.Type{}

			for i in 0 .. math.min(generic_parameters.len, generic_arguments_types.len) {
				mapping[generic_parameters[i]] = generic_arguments_types[i]
			}

			for key, value in additional {
				mapping[key] = value
			}

			return mapping
		}
	}

	if arg_owner is CallExpression {
		if params_owner is SignatureOwner {
			arguments := arg_owner.arguments()
			signature := params_owner.signature() or { return map[string]types.Type{} }
			parameters := signature.parameters()

			arguments_types := arguments.map(infer_type(it))
			parameters_types := parameters.map(infer_type(it))

			mut reifier := GenericTypeReifier{}
			reifier.reify_generic_ts(parameters_types, arguments_types)

			mut mapping := map[string]types.Type{}
			for key, type_ in reifier.implicit_specialization_types_map {
				mapping[key] = type_
			}

			for key, value in additional {
				mapping[key] = value
			}

			return mapping
		}
	}

	return additional
}

fn (g &GenericTypeInferer) infer_qualifier_generic_ts_map(typ types.GenericInstantiationType) map[string]types.Type {
	qualifier_generic_ts := g.extract_instantiation_ts(typ)
	if qualifier_generic_ts.len == 0 {
		return map[string]types.Type{}
	}

	specialization := typ.specialization
	mut mapping := map[string]types.Type{}

	for i in 0 .. math.min(qualifier_generic_ts.len, specialization.len) {
		mapping[qualifier_generic_ts[i]] = specialization[i]
	}

	return mapping
}

fn (g &GenericTypeInferer) extract_instantiation(typ types.Type) ?&types.GenericInstantiationType {
	if typ is types.GenericInstantiationType {
		return typ
	}

	if typ is types.AliasType {
		return g.extract_instantiation(typ.inner)
	}

	if typ is types.PointerType {
		return g.extract_instantiation(typ.inner)
	}

	if typ is types.OptionType {
		return g.extract_instantiation(typ.inner)
	}

	if typ is types.ResultType {
		return g.extract_instantiation(typ.inner)
	}

	return none
}

pub fn (_ &GenericTypeInferer) extract_instantiation_ts(typ types.GenericInstantiationType) []string {
	inner_name := typ.inner.qualified_name()
	elements := stubs_index.get_any_elements_by_name(inner_name)
	if elements.len == 0 {
		return []
	}

	resolved := elements.first()
	if resolved is GenericParametersOwner {
		if generic_parameters := resolved.generic_parameters() {
			return generic_parameters.parameter_names()
		}
	}

	return []
}

fn (_ &GenericTypeInferer) generics_parameter_names(params_owner GenericParametersOwner) []string {
	params := params_owner.generic_parameters() or { return [] }
	return params.parameter_names()
}
