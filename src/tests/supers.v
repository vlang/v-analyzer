module tests

import testing

fn supers() testing.Tester {
	mut t := testing.with_name('supers')

	t.test('super interface with method', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		interface IFoo {
			foo()
		}

		struct /*caret*/FooImpl {}

		fn (f FooImpl) foo() {}
		'.trim_indent())!

		locations := fixture.supers_at_cursor()
		t.assert_has_super_with_name(locations, 'IFoo')!
	})

	t.test('super interface with field', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		interface IFoo {
			foo string
		}

		struct /*caret*/FooImpl {
			foo string
		}
		'.trim_indent())!

		locations := fixture.supers_at_cursor()
		t.assert_has_super_with_name(locations, 'IFoo')!
	})

	t.test('super interface with method and field', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		interface IFoo {
			field string
			foo()
		}

		struct /*caret*/FooImpl {
			field string
		}

		fn (f FooImpl) foo() {}
		'.trim_indent())!

		locations := fixture.supers_at_cursor()
		t.assert_has_super_with_name(locations, 'IFoo')!
	})

	t.test('super interface with method and field with mismatched type', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		interface IFoo {
			field string
			foo()
		}

		struct /*caret*/FooImpl {
			field int
		}

		fn (f FooImpl) foo() {}
		'.trim_indent())!

		locations := fixture.supers_at_cursor()
		t.assert_no_super_with_name(locations, 'IFoo')!
	})

	t.test('super method', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		interface IFoo {
			foo()
		}

		struct FooImpl {}

		fn (f FooImpl) /*caret*/foo() {}
		'.trim_indent())!

		locations := fixture.supers_at_cursor()
		t.assert_has_super_with_name(locations, 'foo')!
	})

	return t
}
