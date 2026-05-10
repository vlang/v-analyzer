module types

for i in 0 .. 10 {
	expr_type(i, 'int')
}

arr := ['str']

for val in arr {
	expr_type(val, 'string')
}

for i, val in arr {
	expr_type(i, 'int')
	expr_type(val, 'string')
}

fixed_arr := ['str']!
expr_type(fixed_arr, '[1]string')

for val in fixed_arr {
	expr_type(val, 'string')
}

for i, val in fixed_arr {
	expr_type(i, 'int')
	expr_type(val, 'string')
}

mp := map[string]int{}

for key, val in mp {
	expr_type(key, 'string')
	expr_type(val, 'int')
}

type MyMap = map[string]int

mp2 := MyMap{}

for key, val in mp2 {
	expr_type(key, 'string')
	expr_type(val, 'int')
}

for val in 'hello' {
	expr_type(val, 'u8')
}

struct Iterator {}

fn (mut i Iterator) next() ?int {
	return 1
}

it := Iterator{}
for val in it {
	expr_type(val, 'int')
}
