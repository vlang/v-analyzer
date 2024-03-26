module tests

import testing

fn types() testing.Tester {
	mut t := testing.with_name('types')

	t.type_test('literals', 'types/literals.vv')
	t.type_test('parameters types', 'types/parameters.vv')
	t.type_test('call expressions', 'types/call_expression.vv')
	t.type_test('type initializer', 'types/type_initializer.vv')
	t.type_test('for loops', 'types/for_loops.vv')
	t.type_test('slice and index expression', 'types/slice_and_index_expression.vv')
	t.type_test('function literal', 'types/function_literal.vv')
	t.type_test('pointers', 'types/pointers.vv')
	t.type_test('bool operators', 'types/bool_operators.vv')
	t.type_test('unsafe expression', 'types/unsafe_expression.vv')
	t.type_test('if expression', 'types/if_expression.vv')
	t.type_test('match expression', 'types/match_expression.vv')
	t.type_test('map init expression', 'types/map_init_expression.vv')
	t.type_test('chan type', 'types/chan_type.vv')
	t.type_test('struct fields', 'types/fields.vv')
	t.type_test('receiver', 'types/receiver.vv')
	t.type_test('json decode', 'types/json_decode.vv')
	t.type_test('generics', 'types/generics.vv')
	t.type_test('constants', 'types/constants.vv')
	t.type_test('for loop', 'types/for_loop.vv')

	return t
}
