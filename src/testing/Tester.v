module testing

import os
import lsp
import time
import term
import loglib
import analyzer.psi

pub struct TesterStats {
pub:
	passed   int
	failed   int
	skipped  int
	duration time.Duration
}

pub fn (s TesterStats) print() {
	println('${term.bold('Passed')}: ${s.passed}, ${term.bold('Failed')}: ${s.failed}, ${term.bold('Skipped')}: ${s.skipped}')
	println('${term.bold('Duration')}: ${s.duration}')
}

pub fn (s TesterStats) merge(other TesterStats) TesterStats {
	return TesterStats{
		passed: s.passed + other.passed
		failed: s.failed + other.failed
		skipped: s.skipped + other.skipped
		duration: s.duration + other.duration
	}
}

pub struct Tester {
pub:
	name string
mut:
	tests             []&Test
	last_fixture      &Fixture = unsafe { nil }
	last_slow_fixture &Fixture = unsafe { nil }
}

pub fn with_name(name string) Tester {
	return Tester{
		name: name
	}
}

pub fn (mut t Tester) failed_tests() []&Test {
	return t.tests.filter(it.state == .failed)
}

pub fn (mut t Tester) create_or_reuse_fixture(with_stdlib bool) &Fixture {
	if with_stdlib {
		if !isnil(t.last_slow_fixture) {
			return t.last_slow_fixture
		}
	} else {
		if !isnil(t.last_fixture) {
			return t.last_fixture
		}
	}

	loglib.set_level(.warn) // we don't want to see info messages in tests

	mut fixture := new_fixture()
	fixture.initialize(with_stdlib) or {
		println('Cannot initialize fixture: ${err}')
		return fixture
	}

	fixture.initialized() or {
		println('Cannot run initialized request: ${err}')
		return fixture
	}

	if with_stdlib {
		t.last_slow_fixture = fixture
	} else {
		t.last_fixture = fixture
	}
	return fixture
}

pub fn (mut t Tester) run(run_only string) {
	mut fixture := t.create_or_reuse_fixture(false)

	for mut test in t.tests {
		if run_only != '' && test.name != run_only {
			test.state = .skipped
			continue
		}

		if test.with_stdlib {
			mut fixture_with_stdlib := t.create_or_reuse_fixture(true)
			test.run(mut fixture_with_stdlib)
			continue
		}
		test.run(mut fixture)
	}
}

pub fn (t Tester) stats() TesterStats {
	mut passed := 0
	mut failed := 0
	mut skipped := 0
	mut duration := 0

	for test in t.tests {
		if test.state == .skipped {
			skipped += 1
		} else if test.state == .failed {
			failed += 1
		} else {
			passed += 1
		}

		duration += test.duration
	}

	return TesterStats{
		passed: passed
		failed: failed
		skipped: skipped
		duration: duration
	}
}

pub fn (mut t Tester) test(name string, test_func TestFunc) {
	mut test := &Test{
		name: name
		func: test_func
	}
	t.tests << test
}

pub fn (mut t Tester) slow_test(name string, test_func TestFunc) {
	mut test := &Test{
		name: name
		func: test_func
		with_stdlib: true
	}
	t.tests << test
}

pub fn (mut t Tester) type_test(name string, filepath string) {
	mut test := &Test{
		name: name
	}
	t.tests << test

	test.func = fn [filepath] (mut test Test, mut fixture Fixture) ! {
		fixture.configure_by_file(filepath) or {
			println('Cannot configure fixture: ${err}')
			return error('Cannot configure fixture: ${err}')
		}
		file := fixture.ls.get_file(fixture.current_file.uri()) or {
			return error('File not found: ${fixture.current_file.uri()}')
		}

		mut expr_calls := []psi.CallExpression{}
		mut expr_calls_ptr := &expr_calls

		psi.inspect(file.psi_file.root, fn [mut expr_calls_ptr] (it psi.PsiElement) bool {
			if it is psi.CallExpression {
				expr := it.expression() or { return true }
				text := expr.get_text()
				if text != 'expr_type' {
					return true
				}

				arguments := it.arguments()
				if arguments.len != 2 {
					return true
				}

				expr_calls_ptr << it
				return false
			}
			return true
		})

		for call in expr_calls {
			arguments := call.arguments()
			if arguments.len != 2 {
				continue
			}

			first := arguments[0]
			second := arguments[1]

			typ := psi.infer_type(first)
			got_type_string := typ.readable_name()

			if second is psi.Literal {
				first_child := second.first_child() or { continue }
				if first_child is psi.StringLiteral {
					expected_type_string := first_child.content()

					if expected_type_string != got_type_string {
						test.state = .failed
						test.message = '
								In file ${call.containing_file.path}:${
							call.text_range().line + 1}

								Type mismatch.
								Expected: ${expected_type_string}
								Found:    ${got_type_string}

							'.trim_indent()
						break
					}
				}
			}
		}
	}
}

pub fn (mut t Tester) documentation_test(name string, filepath string) {
	mut test := &Test{
		name: name
	}
	t.tests << test

	test.func = fn [filepath] (mut test Test, mut fixture Fixture) ! {
		fixture.configure_by_file(filepath) or {
			return test.fail('Cannot configure fixture: ${err}')
		}

		hover := fixture.documentation_at_cursor() or {
			return test.fail('Cannot get documentation at cursor')
		}

		if hover.contents !is lsp.MarkupContent {
			return test.fail('Documentation is not a MarkupContent')
		}

		markup := hover.contents as lsp.MarkupContent

		if markup.kind != lsp.markup_kind_markdown {
			return test.fail('Documentation is not a Markdown')
		}

		markdown_filepath := filepath + '.md'
		markdown := os.read_file('testdata/${markdown_filepath}') or {
			return test.fail('Cannot read expected .md file: ${err}')
		}

		// if true {
		// 	os.write_file('testdata/${markdown_filepath}', markup.value) or {}
		// 	return
		// }

		test.assert_eq(markup.value.trim_right('\n'), markdown.trim_right('\n'))!
	}
}

pub fn (mut t Tester) scratch_test(name string, test_func fn (mut test Test, mut fixture Fixture) !) {
	mut fixture := new_fixture()
	fixture.initialize(false) or {
		println('Test failed: ${err}')
		return
	}

	mut test := &Test{
		name: name
	}
	t.tests << test
	test_func(mut test, mut fixture) or { println('Test failed: ${err}') }

	test.print()
}
