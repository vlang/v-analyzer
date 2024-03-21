module types

fn types_foo(a string) string {}

fn types_foo1(a string) (int, string) {}

fn types_foo2(a string, b int) (int, string) {}

fn types_foo3(a string, b int) {}

fn types_foo4() {}

fn main() {
	expr_type(types_foo, 'fn (string) string')
	expr_type(types_foo1, 'fn (string) (int, string)')
	expr_type(types_foo2, 'fn (string, int) (int, string)')
	expr_type(types_foo3, 'fn (string, int)')
	expr_type(types_foo4, 'fn ()')

	expr_type(fn () {}, 'fn ()')
	expr_type(fn (i int) {}, 'fn (int)')
	expr_type(fn (i int) string {}, 'fn (int) string')
	expr_type(fn (i int, s string) string {}, 'fn (int, string) string')
}

fn calls() {
	func := fn (i int) string {}
	expr_type(func(), 'string')

	func1 := fn (i int) int {}
	expr_type(func1(), 'int')

	func2 := fn (i int) int {}()
	expr_type(func2, 'int')
}
