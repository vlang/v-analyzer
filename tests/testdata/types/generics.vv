module types

struct GenericStruct[T] {}

fn GenericStruct.static_method[T]() string {
	return 'hello'
}

fn main() {
	expr_type(GenericStruct[int]{}, 'types.GenericStruct[int]')
	expr_type(GenericStruct.static_method[string](), 'string')
}
