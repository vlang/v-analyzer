module types

fn main() {
	a := match true {
		false { 100 }
		else { 100 }
	}
	expr_type(a, 'int')

	b := match true {
		false {
			inner := 100
			inner
		}
		else {
			100
		}
	}
	expr_type(b, 'int')
}
