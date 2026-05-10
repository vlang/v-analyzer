module types

struct FieldsFoo {
	name  string
	parts []int
	cb    fn () string
}

fn main() {
	foo := FieldsFoo{
		name: 'foo'
		parts: [1, 2, 3]
	}

	expr_type(foo.name, 'string')
	expr_type(foo.parts, '[]int')
	expr_type(foo.cb, 'fn () string')
	expr_type(foo.cb(), 'string')
}
