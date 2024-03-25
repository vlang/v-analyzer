module types

fn main() {
	a := if true {
		100
	} else {
		200
	}
	expr_type(a, 'int')

	b := if true {
		'100'
	} else {
		'200'
	}
	expr_type(b, 'string')

	c := if true {
		unsafe { 100 }
	} else {
		200
	}
	expr_type(c, 'int')

	d := if true {
		inner := unsafe { 100 }
		inner
	} else {
		200
	}
	expr_type(d, 'int')

	e := if true {
		inner := map[int]string{}
		inner[100]
	} else {
		200
	}
	expr_type(e, 'string')

	f := if true {
		unknown
	} else {
		200
	}
	expr_type(f, 'int')

	g := $if macos {
		1
	} $else {
		2
	}
	expr_type(g, 'int')
}

fn get_opt() ?int {
	return 100
}

fn get_res() !int {
	return 100
}

fn unwrapping() {
	if a := get_opt() {
		expr_type(a, 'int')
	}

	if a := get_res() {
		expr_type(a, 'int')
	}
}
