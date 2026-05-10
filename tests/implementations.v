module tests

import testing

fn implementations() testing.Tester {
	mut t := testing.with_name('implementations')

	t.test('method interface implementation', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		interface /*caret*/IFoo {
			foo()
		}

		struct FooImpl {}

		fn (f FooImpl) foo() {}
		'.trim_indent())!

		locations := fixture.implementation_at_cursor()
		t.assert_has_implementation_with_name(locations, 'FooImpl')!
	})

	t.test('method interface implementation with return type', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		interface /*caret*/IFoo {
			foo() string
		}

		struct FooImpl {}

		fn (f FooImpl) foo() string {}
		'.trim_indent())!

		locations := fixture.implementation_at_cursor()
		t.assert_has_implementation_with_name(locations, 'FooImpl')!
	})

	t.test('method interface implementation with parameters', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		interface /*caret*/IFoo {
			foo(age int, name string) string
		}

		struct FooImpl {}

		fn (f FooImpl) foo(age int, name string) string {}
		'.trim_indent())!

		locations := fixture.implementation_at_cursor()
		t.assert_has_implementation_with_name(locations, 'FooImpl')!
	})

	t.test('method interface implementation with parameters, parameters types mismatch',
		fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		interface /*caret*/IFoo {
			foo(age int, name ?string) string
		}

		struct FooImpl {}

		fn (f FooImpl) foo(age int, name string) string {}
		'.trim_indent())!

		locations := fixture.implementation_at_cursor()
		t.assert_no_implementation_with_name(locations, 'FooImpl')!
	})

	t.test('method interface implementation with fields', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		interface /*caret*/IFoo {
			foo string
		}

		struct FooImpl {
			foo string
		}
		'.trim_indent())!

		locations := fixture.implementation_at_cursor()
		t.assert_has_implementation_with_name(locations, 'FooImpl')!
	})

	t.test('method interface implementation with fields, types mismatch', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		interface /*caret*/IFoo {
			foo ?string
		}

		struct FooImpl {
			foo string
		}
		'.trim_indent())!

		locations := fixture.implementation_at_cursor()
		t.assert_no_implementation_with_name(locations, 'FooImpl')!
	})

	t.test('method implementation', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		interface IFoo {
			/*caret*/foo()
		}

		struct FooImpl {}

		fn (f FooImpl) foo() {}
		'.trim_indent())!

		locations := fixture.implementation_at_cursor()
		t.assert_has_implementation_with_name(locations, 'foo')!
	})

	return t
}
