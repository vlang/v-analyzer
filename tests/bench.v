module tests

import testing

fn bench() testing.BenchmarkRunner {
	mut b := testing.BenchmarkRunner{
		last_fixture: unsafe { nil }
	}

	b.bench('inlay hints', fn (mut b testing.Benchmark, mut fixture testing.Fixture) ! {
		fixture.configure_by_file('benchmarks/inlay_hints.vv')!

		b.start()

		hints := fixture.compute_inlay_hints()
		println('Count: ${hints.len}')

		b.stop()
		b.print_results()
	})

	b.bench('semantic tokens', fn (mut b testing.Benchmark, mut fixture testing.Fixture) ! {
		fixture.configure_by_file('benchmarks/checker.vv')!

		b.start()

		tokens := fixture.compute_semantic_tokens()
		println('Count: ${tokens.data.len / 5}')

		b.stop()
		b.print_results()
	})

	return b
}
