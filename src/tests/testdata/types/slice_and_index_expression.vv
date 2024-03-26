module types

fn main() {
	arr := [1, 2, 3]
	expr_type(arr[0], 'int')
	expr_type(arr[0..10], '[]int')

	fixed_arr := [1, 2, 3]!
	expr_type(fixed_arr[0], 'int')
	expr_type(fixed_arr[0..2], '[]int')

	s := 'string'
	expr_type(s[0], 'u8')
	expr_type(s[0..2], 'string')
}
