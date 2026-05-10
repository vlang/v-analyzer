module types

struct Foo {}

fn main() {
	mp1 := {
		0: 100
	}
	expr_type(mp1, 'map[int]int')
	expr_type(mp1[0], 'int')

	mp2 := {
		'0': 100
	}
	expr_type(mp2, 'map[string]int')
	expr_type(mp2[0], 'int')

	mp3 := {
		0: Foo{}
	}
	expr_type(mp3, 'map[int]types.Foo')
	expr_type(mp3[0], 'types.Foo')
}
