module types

expr_type(1 in [], 'bool')
expr_type(1 !in [], 'bool')
expr_type(1 is Foo, 'bool')
expr_type(1 !is Foo, 'bool')
expr_type(1 == 1, 'bool')
expr_type(1 != 1, 'bool')
expr_type(1 > 1, 'bool')
expr_type(1 >= 1, 'bool')
expr_type(1 < 1, 'bool')
expr_type(1 <= 1, 'bool')
expr_type(true && false, 'bool')
expr_type(true || false, 'bool')
expr_type(!false, 'bool')

expr_type(select {
	a := <-ch {}
}, 'bool')
