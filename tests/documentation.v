module main

import testing

fn documentation() testing.Tester {
	mut t := testing.with_name('documentation')

	t.documentation_test('rendered', 'documentation/rendered.v')

	return t
}
