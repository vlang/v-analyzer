module tests

import testing

fn definitions() testing.Tester {
	mut t := testing.with_name('definitions')

	t.test('simple variable definition', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		fn main() {
			name := 100
			println(na/*caret*/me)
		}
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!

		first := locations.first()
		t.assert_uri(first.target_uri, fixture.current_file_uri())!
		t.assert_definition_name(first, 'name')!
	})

	t.test('variable definition from outer scope', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		fn main() {
			name := 100
			if true {
				println(na/*caret*/me)
			}
		}
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!

		first := locations.first()
		t.assert_uri(first.target_uri, fixture.current_file_uri())!
		t.assert_definition_name(first, 'name')!
	})

	t.test('variable definition from outer scope after inner scope', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		fn main() {
			if true {
				println(so/*caret*/me_variable)
			}
			some_variable := 100
		}
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_no_definition(locations)!
	})

	t.test('variable definition from for loop', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		fn main() {
			for index := 0; index < 100; index++ {
				println(inde/*caret*/x)
			}
		}
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!

		first := locations.first()
		t.assert_uri(first.target_uri, fixture.current_file_uri())!
		t.assert_definition_name(first, 'index')!
	})

	t.test('variable definition from for in loop', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		fn main() {
			for index in 0 .. 100 {
				println(inde/*caret*/x)
			}
		}
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!

		first := locations.first()
		t.assert_uri(first.target_uri, fixture.current_file_uri())!
		t.assert_definition_name(first, 'index')!
	})

	t.test('variable definition from if unwrapping', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		fn main() {
			if value := foo() {
				println(val/*caret*/ue)
			}
		}
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!

		first := locations.first()
		t.assert_uri(first.target_uri, fixture.current_file_uri())!
		t.assert_definition_name(first, 'value')!
	})

	// TODO: This probably should be prohibited
	t.test('variable definition from if unwrapping in else', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		fn main() {
			if value := foo() {

			} else {
				println(val/*caret*/ue)
			}
 		}
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!

		first := locations.first()
		t.assert_uri(first.target_uri, fixture.current_file_uri())!
		t.assert_definition_name(first, 'value')!
	})

	t.test('variable definition from if unwrapping from outside', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		fn main() {
			if some_variable := foo() {}

			println(some/*caret*/_variable)
 		}
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_no_definition(locations)!
	})

	t.test('field definition', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		struct FooStruct {
			name string
		}

		fn main() {
			foo := FooStruct{}
			println(foo.na/*caret*/me)
		}
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!
		first := locations.first()
		t.assert_uri(first.target_uri, fixture.current_file_uri())!
		t.assert_definition_name(first, 'name')!
	})

	t.test('method definition', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		struct Foo {
			name string
		}

		fn (foo Foo) get_name() string {
			return foo.name
		}

		fn main() {
			foo := Foo{}
			println(foo.get_na/*caret*/me())
		}
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!
		first := locations.first()
		t.assert_uri(first.target_uri, fixture.current_file_uri())!
		t.assert_definition_name(first, 'get_name')!
	})

	t.test('top level variable', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		name := 100
		println(na/*caret*/me)
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!

		first := locations.first()
		t.assert_uri(first.target_uri, fixture.current_file_uri())!
		t.assert_definition_name(first, 'name')!
	})

	t.test('top level variable from outer scope', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		name := 100
		if true {
			println(na/*caret*/me)
		}
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!

		first := locations.first()
		t.assert_uri(first.target_uri, fixture.current_file_uri())!
		t.assert_definition_name(first, 'name')!
	})

	t.test('it as function parameter', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', "
		fn foo(it int) {
			if i/*caret*/t.str() == 1 {
				println('one')
			}
		}
		".trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!

		first := locations.first()
		t.assert_uri(first.target_uri, fixture.current_file_uri())!
		t.assert_definition_name(first, 'it')!
	})

	t.slow_test('shell script implicit os module', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.vsh', '
		abs_/*caret*/path()
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!

		first := locations.first()
		t.assert_uri_from_stdlib(first.target_uri, 'filepath.v')!
	})

	t.test('shell script implicit os module constant', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.vsh', '
			ar/*caret*/gs
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!

		first := locations.first()
		t.assert_uri_from_stdlib(first.target_uri, 'os.c.v')!
	})

	t.slow_test('shell script local function', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.vsh', '
		fn some_fn() {}

		/*caret*/some_fn()
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!

		first := locations.first()
		t.assert_uri(first.target_uri, fixture.current_file_uri())!
		t.assert_definition_name(first, 'some_fn')!
	})

	t.slow_test('shell script local constant', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.vsh', '
		const some_constant = 100

		/*caret*/some_constant
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!

		first := locations.first()
		t.assert_uri(first.target_uri, fixture.current_file_uri())!
		t.assert_definition_name(first, 'some_constant')!
	})

	t.test('static methods', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.vsh', '
		module main

		struct TestStruct {}

		fn TestStruct.static_method() {}

		fn main() {
			TestStruct.static/*caret*/_method()
		}
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!

		first := locations.first()
		t.assert_uri(first.target_uri, fixture.current_file_uri())!
		t.assert_definition_name(first, 'static_method')!
	})

	t.test('enum inside special flag field method call', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.vsh', '
		module main

		[flag]
		enum Colors {
			red
			green
		}

		fn main() {
			mut color := Colors.green
			color.has(.r/*caret*/ed)
		}
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!

		first := locations.first()
		t.assert_uri(first.target_uri, fixture.current_file_uri())!
		t.assert_definition_name(first, 'red')!
	})

	t.test('enum fields or', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.vsh', '
		module main

		[flag]
		enum Colors {
			red
			green
		}

		fn main() {
			mut color := Colors.green | .r/*caret*/ed
		}
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!

		first := locations.first()
		t.assert_uri(first.target_uri, fixture.current_file_uri())!
		t.assert_definition_name(first, 'red')!
	})

	t.test('implicit str method', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.vsh', '
		module main

		struct Foo {}

		fn main() {
			mut foo := Foo{}
			foo.s/*caret*/tr()
		}
		'.trim_indent())!

		locations := fixture.definition_at_cursor()
		t.assert_has_definition(locations)!

		first := locations.first()
		t.assert_uri_from_stubs(first.target_uri, 'implicit.v')!
	})

	return t
}
