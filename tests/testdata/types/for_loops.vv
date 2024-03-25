module types

fn arrays() {
	for index in 0 .. 10 {
		expr_type(index, 'int')
	}

	int_array := [1, 2, 3]

	for index in int_array {
		expr_type(index, 'int')
	}

	for index, value in int_array {
		expr_type(index, 'int')
		expr_type(value, 'int')
	}

	string_array := ['1', '2', '3']

	for index in string_array {
		expr_type(index, 'string')
	}

	for index, value in string_array {
		expr_type(index, 'int')
		expr_type(value, 'string')
	}

	bool_array := [true, false]

	for index in bool_array {
		expr_type(index, 'bool')
	}

	for index, value in bool_array {
		expr_type(index, 'int')
		expr_type(value, 'bool')
	}
}

fn maps() {
	mp := map[string]int{}

	for key, value in mp {
		expr_type(key, 'string')
		expr_type(value, 'int')
	}
}

fn strings() {
	mp := ''

	for value in mp {
		expr_type(value, 'u8')
	}

	for key, value in mp {
		expr_type(key, 'int')
		expr_type(value, 'u8')
	}
}
