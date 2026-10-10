module psi

import analyzer.psi.types
import math

pub struct GenericTypeReifier {
mut:
	implicit_specialization_types_map map[string]types.Type
}

pub fn (mut g GenericTypeReifier) reify_generic_ts(param_types []types.Type, arg_types []types.Type) {
	for i in 0 .. math.min(param_types.len, arg_types.len) {
		g.reify_generic_t(param_types[i], arg_types[i])
	}
}

fn (mut g GenericTypeReifier) reify_generic_t(param_type types.Type, arg_type types.Type) {
	if param_type is types.GenericType {
		g.implicit_specialization_types_map[param_type.name()] = arg_type
	}

	if param_type is types.GenericInstantiationType {
		if arg_type is types.GenericInstantiationType {
			for i in 0 .. math.min(param_type.specialization.len, arg_type.specialization.len) {
				g.reify_generic_t(param_type.specialization[i], arg_type.specialization[i])
			}
		}
	}

	if param_type is types.MapType {
		if arg_type is types.MapType {
			g.reify_generic_t(param_type.key, arg_type.key)
			g.reify_generic_t(param_type.value, arg_type.value)
		}
	}

	if param_type is types.ResultType {
		if arg_type is types.ResultType {
			g.reify_generic_t(param_type.inner, arg_type.inner)
		} else {
			g.reify_generic_t(param_type.inner, arg_type)
		}
	}

	if param_type is types.OptionType {
		if arg_type is types.OptionType {
			g.reify_generic_t(param_type.inner, arg_type.inner)
		} else {
			g.reify_generic_t(param_type.inner, arg_type)
		}
	}

	if param_type is types.PointerType {
		if arg_type is types.PointerType {
			g.reify_generic_t(param_type.inner, arg_type.inner)
		} else {
			g.reify_generic_t(param_type.inner, arg_type)
		}
	}

	if param_type is types.ChannelType {
		if arg_type is types.ChannelType {
			g.reify_generic_t(param_type.inner, arg_type.inner)
		} else {
			g.reify_generic_t(param_type.inner, arg_type)
		}
	}

	if param_type is types.ArrayType {
		if arg_type is types.ArrayType {
			g.reify_generic_t(param_type.inner, arg_type.inner)
		} else {
			g.reify_generic_t(param_type.inner, arg_type)
		}
	}

	if param_type is types.FixedArrayType {
		if arg_type is types.FixedArrayType {
			g.reify_generic_t(param_type.inner, arg_type.inner)
		} else {
			g.reify_generic_t(param_type.inner, arg_type)
		}
	}

	if param_type is types.FunctionType {
		if arg_type is types.FunctionType {
			for i in 0 .. math.min(param_type.params.len, arg_type.params.len) {
				g.reify_generic_t(param_type.params[i], arg_type.params[i])
			}

			g.reify_generic_t(param_type.result, arg_type.result)
		}
	}
}
