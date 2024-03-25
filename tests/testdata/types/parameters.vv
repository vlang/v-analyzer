module types

struct FooBar {}

fn foo(param &FooBar, param2 []&FooBar) {
	expr_type(param, '&types.FooBar')
	expr_type(param2, '[]&types.FooBar')
}

fn foo2(variadic ...FooBar) {
	expr_type(variadic, '[]types.FooBar')
}
