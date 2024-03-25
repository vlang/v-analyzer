module tests

import testing
import server.completion.providers

fn completion() testing.Tester {
	mut t := testing.with_name('completion')

	t.test('struct field completion', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		struct SomeFoo {
			name string
		}

		fn main() {
			foo := SomeFoo{}
			foo./*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()
		t.assert_has_only_completion_with_labels(items, 'name', 'str')!
	})

	t.test('struct method completion', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		struct Foo {}

		fn (foo Foo) some_method() {
		}

		fn main() {
			foo := Foo{}
			foo./*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()
		t.assert_has_only_completion_with_labels(items, 'some_method', 'str')!
	})

	t.test('variables completion', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		fn main() {
			name := 100
			/*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, 'name')!
	})

	t.test('assert inside test file', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1_test.v', '
		fn test_something() {
			asse/*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, 'assert expr')!
		t.assert_has_completion_with_label(items, 'assert expr, message')!
	})

	t.test('assert as expression', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1_test.v', '
		fn test_something() {
			a := asse/*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_no_completion_with_label(items, 'assert expr')!
		t.assert_no_completion_with_label(items, 'assert expr, message')!
	})

	t.test('assert outside test file', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		fn test_something() {
			asse/*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_no_completion_with_label(items, 'assert expr')!
		t.assert_no_completion_with_label(items, 'assert expr, message')!
	})

	t.test('attributes over function', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		[/*caret*/]
		fn main() {

		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, 'direct_array_access')!
		t.assert_has_completion_with_label(items, "sql: 'value'")!
	})

	t.test('json attribute for field', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		struct Foo {
			some_value string [js/*caret*/]
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, "json: 'someValue'")!
	})

	t.test('json attribute for field with at', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		struct Foo {
			@enum string [js/*caret*/]
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, "json: 'enum'")!
	})

	t.test('json attribute for field with underscore', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		struct Foo {
			type_ string [js/*caret*/]
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, "json: 'type'")!
	})

	t.test('compile time constant', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		@/*caret*/
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, '@FN')!
		t.assert_has_completion_with_label(items, '@FILE_LINE')!
	})

	t.test('function like keywords', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		/*caret*/
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, 'dump()')!
		t.assert_has_completion_with_label(items, 'sizeof()')!
		t.assert_has_completion_with_label(items, 'typeof()')!
		t.assert_has_completion_with_label(items, 'isreftype()')!
		t.assert_has_completion_with_label(items, '__offsetof()')!
	})

	t.test('inits completion', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		/*caret*/
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, 'chan int{}')!
		t.assert_has_completion_with_label(items, 'map[string]int{}')!
		t.assert_has_completion_with_label(items, 'thread int{}')!
	})

	t.test('keywords completion', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		/*caret*/
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, 'true')!
		t.assert_has_completion_with_label(items, 'false')!
		t.assert_has_completion_with_label(items, 'static')!
		t.assert_has_completion_with_label(items, 'none')!
	})

	t.test('continue and break inside loop', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		for {
			/*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, 'break')!
		t.assert_has_completion_with_label(items, 'continue')!
	})

	t.test('continue and break outside loop', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		/*caret*/
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_no_completion_with_label(items, 'break')!
		t.assert_no_completion_with_label(items, 'continue')!
	})

	t.test('module name completion', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		modu/*caret*/
		'.trim_indent())!

		items := fixture.complete_at_cursor()
		if items.len == 0 {
			return t.fail('no completion variants')
		}

		t.assert_has_completion_with_label(items, 'module main')!
		t.assert_has_completion_with_label(items, 'module v_analyzer_test')!
	})

	t.test('module name completion with module clause', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main
		modu/*caret*/
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_no_completion_with_label(items, 'module main')!
		t.assert_no_completion_with_label(items, 'module v_analyzer_test')!
	})

	t.test('nil keyword completion outside unsafe', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		/*caret*/
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_insert_text(items, 'unsafe { nil }')!
	})

	t.test('nil keyword completion inside unsafe', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		unsafe {
			/*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_insert_text(items, 'nil')!
	})

	t.test('or block completion', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		foo() /*caret*/
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, 'or { ... }')!
		t.assert_has_completion_with_label(items, 'or { panic(err) }')!
	})

	t.test('unsafe block completion as expression', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		a := /*caret*/
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_insert_text(items, 'unsafe { $0 }')!
	})

	t.test('unsafe block completion as statements', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		/*caret*/
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_insert_text(items, 'unsafe {\n\t$0\n}')!
	})

	t.test('defer block completion', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		/*caret*/
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, 'defer { ... }')!
	})

	t.test('return completion inside function without return type', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		fn foo() {
			/*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, 'return')!
	})

	t.test('return completion inside function with return type', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		fn foo() int {
			/*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, 'return ')!
	})

	t.test('return completion inside function with bool return type', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		fn foo() bool {
			/*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, 'return ')!
		t.assert_has_completion_with_label(items, 'return true')!
		t.assert_has_completion_with_label(items, 'return false')!
	})

	t.test('top level completion', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		/*caret*/
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		for label, _ in providers.top_level_map {
			t.assert_has_completion_with_label(items, label)!
			t.assert_has_completion_with_label(items, 'pub ${label}')!
		}
	})

	t.test('no top level completion', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		fn main() {
			/*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		for label, _ in providers.top_level_map {
			t.assert_no_completion_with_label(items, label)!
			t.assert_no_completion_with_label(items, 'pub ${label}')!
		}
	})

	t.test('parameters completion', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		fn foo(param_name_1 int, param_name_2 string) {
			/*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, 'param_name_1')!
		t.assert_has_completion_with_label(items, 'param_name_2')!
	})

	t.test('receiver name completion', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		struct Foo {}

		fn (foo_receiver Foo) bar() {
			/*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, 'foo_receiver')!
	})

	t.test('struct as type completion', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('foo/foo.v', '
		module foo

		pub struct Foo {}
		'.trim_indent())!

		fixture.configure_by_text('1.v', '
		import foo

		fn bar() foo./*caret*/ {

		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_insert_text(items, 'Foo')!
		t.assert_no_completion_with_insert_text(items, 'Foo{$1}$0')!
	})

	t.test('struct as expression completion', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('foo/foo.v', '
		module foo

		pub struct Foo {}
		'.trim_indent())!

		fixture.configure_by_text('1.v', '
		import foo

		fn bar() {
			foo./*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_insert_text(items, 'Foo{$1}$0')!
		t.assert_no_completion_with_insert_text(items, 'Foo')!
	})

	t.test('imported modules completion', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		import arrays
		import net.http
		import foo as bar
		import bar.baz as qux

		/*caret*/
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_label(items, 'arrays')!
		t.assert_has_completion_with_label(items, 'http')!
		t.assert_no_completion_with_label(items, 'foo')!
		t.assert_has_completion_with_label(items, 'bar')!
		t.assert_no_completion_with_label(items, 'baz')!
		t.assert_has_completion_with_label(items, 'qux')!
	})

	t.test('function without params completion', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		fn function_without_params() {}

		fn bar() {
			function_without_params/*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_insert_text(items, 'function_without_params()$0')!
		t.assert_no_completion_with_insert_text(items, 'function_without_params($1)$0')!
	})

	t.test('function with params completion', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		fn function_with_params(a int) {}

		fn bar() {
			function_with_params/*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_insert_text(items, 'function_with_params($1)$0')!
		t.assert_no_completion_with_insert_text(items, 'function_with_params()$0')!
	})

	t.test('static method completion', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		struct TestStruct {}

		fn TestStruct.static_method() {}

		fn main() {
			TestStruct./*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_insert_text(items, 'static_method()$0')!
	})

	t.test('enum methods', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		enum Colors {
			red
			green
		}

		fn (c Colors) some_method() {}

		fn main() {
			c := Colors.red
			c./*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_insert_text(items, 'red')!
		t.assert_has_completion_with_insert_text(items, 'green')!
		t.assert_has_completion_with_insert_text(items, 'some_method()$0')!
		t.assert_no_completion_with_insert_text(items, 'all($1)$0')!
		t.assert_no_completion_with_insert_text(items, 'has($1)$0')!
		t.assert_no_completion_with_insert_text(items, 'clear($1)$0')!
		t.assert_no_completion_with_insert_text(items, 'set($1)$0')!
		t.assert_no_completion_with_insert_text(items, 'toggle($1)$0')!
	})

	t.test('enum flag methods', fn (mut t testing.Test, mut fixture testing.Fixture) ! {
		fixture.configure_by_text('1.v', '
		module main

		[flag]
		enum Colors {
			red
			green
		}

		fn main() {
			c := Colors.red
			c./*caret*/
		}
		'.trim_indent())!

		items := fixture.complete_at_cursor()

		t.assert_has_completion_with_insert_text(items, 'red')!
		t.assert_has_completion_with_insert_text(items, 'green')!
		t.assert_has_completion_with_insert_text(items, 'all($1)$0')!
		t.assert_has_completion_with_insert_text(items, 'has($1)$0')!
		t.assert_has_completion_with_insert_text(items, 'clear($1)$0')!
		t.assert_has_completion_with_insert_text(items, 'set($1)$0')!
		t.assert_has_completion_with_insert_text(items, 'toggle($1)$0')!
	})

	return t
}
