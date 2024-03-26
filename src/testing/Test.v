module testing

import term
import lsp
import time
import strings

pub type TestFunc = fn (mut test Test, mut fixture Fixture) !

pub enum TestState {
	passed
	failed
	skipped
}

pub struct Test {
mut:
	fixture     &Fixture = unsafe { nil }
	name        string
	func        TestFunc = unsafe { nil }
	state       TestState
	message     string
	with_stdlib bool
	duration    time.Duration
}

pub fn (mut t Test) run(mut fixture Fixture) {
	watch := time.new_stopwatch(auto_start: true)
	t.fixture = fixture
	t.func(mut t, mut fixture) or {}
	t.duration = watch.elapsed()
	t.print()
}

pub fn (mut t Test) fail(msg string) ! {
	t.state = .failed
	t.message = msg
	return error(msg)
}

pub fn (mut t Test) assert_eq[T](left T, right T) ! {
	if left != right {
		t.fail('expected ${left}, but got ${right}')!
	}
}

pub fn (mut t Test) assert_definition_name(location lsp.LocationLink, name string) ! {
	link_text := t.fixture.text_at_range(location.target_selection_range)
	if link_text != name {
		t.fail('expected definition "${name}", but got "${link_text}"')!
	}
}

pub fn (mut t Test) assert_no_definition(locations []lsp.LocationLink) ! {
	if locations.len != 0 {
		t.fail('expected no definition, but got ${locations.len}')!
	}
}

pub fn (mut t Test) assert_has_definition(locations []lsp.LocationLink) ! {
	if locations.len == 0 {
		t.fail('no definition found')!
	}
}

pub fn (mut t Test) assert_has_completion_with_label(items []lsp.CompletionItem, name string) ! {
	for item in items {
		if item.label == name {
			return
		}
	}

	t.fail('expected completion "${name}" not found')!
}

pub fn (mut t Test) assert_has_only_completion_with_labels(items []lsp.CompletionItem, names ...string) ! {
	if items.len != names.len {
		t.fail('expected ${names.len} completions, but got ${items.len}')!
	}

	for name in names {
		t.assert_has_completion_with_label(items, name)!
	}
}

pub fn (mut t Test) assert_has_completion_with_insert_text(items []lsp.CompletionItem, name string) ! {
	if items.len == 0 {
		t.fail('no completions found')!
	}

	for item in items {
		if item.insert_text == name {
			return
		}
	}

	t.fail('expected completion "${name}" not found')!
}

pub fn (mut t Test) assert_no_completion_with_insert_text(items []lsp.CompletionItem, name string) ! {
	for item in items {
		if item.insert_text == name {
			t.fail('unexpected completion "${name}" found')!
		}
	}
}

pub fn (mut t Test) assert_no_completion_with_label(items []lsp.CompletionItem, name string) ! {
	for item in items {
		if item.label == name {
			t.fail('unexpected completion "${name}" found')!
		}
	}
}

pub fn (mut t Test) assert_has_implementation_with_name(items []lsp.Location, name string) ! {
	for item in items {
		link_text := t.fixture.text_at_range(item.range)
		if link_text == name {
			return
		}
	}

	t.fail('expected implementation "${name}" not found')!
}

pub fn (mut t Test) assert_no_implementation_with_name(items []lsp.Location, name string) ! {
	for item in items {
		link_text := t.fixture.text_at_range(item.range)
		if link_text == name {
			t.fail('unexpected implementation "${name}" found')!
		}
	}
}

pub fn (mut t Test) assert_has_super_with_name(items []lsp.Location, name string) ! {
	for item in items {
		link_text := t.fixture.text_at_range(item.range)
		if link_text == name {
			return
		}
	}

	t.fail('expected super "${name}" not found')!
}

pub fn (mut t Test) assert_no_super_with_name(items []lsp.Location, name string) ! {
	for item in items {
		link_text := t.fixture.text_at_range(item.range)
		if link_text == name {
			t.fail('unexpected super "${name}" found')!
		}
	}
}

pub fn (mut t Test) assert_uri(left lsp.DocumentUri, right lsp.DocumentUri) ! {
	left_normalized := left.normalize()
	right_normalized := right.normalize()
	if left_normalized.compare(right_normalized) != 0 {
		t.fail('expected ${left_normalized}, but got ${right_normalized}')!
	}
}

pub fn (mut t Test) assert_uri_from_stdlib(left lsp.DocumentUri, filename string) ! {
	if !left.contains('vlib') {
		t.fail('expected ${left} to be inside "vlib"')!
	}

	if !left.ends_with(filename) {
		t.fail('expected ${left} to end with ${filename} but got ${left}')!
	}
}

pub fn (mut t Test) assert_uri_from_stubs(left lsp.DocumentUri, filename string) ! {
	if !left.contains('stubs') {
		t.fail('expected ${left} to be inside "stubs"')!
	}

	if !left.ends_with(filename) {
		t.fail('expected ${left} to end with ${filename} but got ${left}')!
	}
}

pub fn (t Test) print() {
	mut sb := strings.new_builder(100)
	sb.write_string('${t.duration:10} ')

	if t.state == .failed {
		sb.write_string(term.red('[FAILED] '))
		sb.write_string(t.name)
		sb.write_string('\n')
		sb.write_string('      ${t.message}\n')
	} else if t.state == .passed {
		sb.write_string(term.green('[PASSED] '))
		sb.write_string(t.name)
		sb.write_string('\n')
	}

	print(sb.str())
}
