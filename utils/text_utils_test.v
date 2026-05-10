module utils

fn test_pascal_case_to_snake_case() {
	assert pascal_case_to_snake_case('CamelCase') == 'camel_case'
	assert pascal_case_to_snake_case('SomeValue') == 'some_value'
	assert pascal_case_to_snake_case('SomeValue') == 'some_value'
	assert pascal_case_to_snake_case('SomeValue1') == 'some_value_1'
	assert pascal_case_to_snake_case('Some') == 'some'
}

fn test_snake_case_to_camel_case() {
	assert snake_case_to_camel_case('snake_case') == 'snakeCase'
	assert snake_case_to_camel_case('some_value') == 'someValue'
	assert snake_case_to_camel_case('some_value_1') == 'someValue1'
	assert snake_case_to_camel_case('some') == 'some'
}
