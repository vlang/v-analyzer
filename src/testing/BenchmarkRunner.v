module testing

pub struct BenchmarkRunner {
mut:
	benchmarks   []&Benchmark
	last_fixture &Fixture
}

pub fn (mut b BenchmarkRunner) create_or_reuse_fixture() &Fixture {
	if !isnil(b.last_fixture) {
		return b.last_fixture
	}

	mut fixture := new_fixture()
	fixture.initialize(false) or {
		println('Cannot initialize fixture: ${err}')
		return fixture
	}

	b.last_fixture = fixture
	return fixture
}

pub fn (mut b BenchmarkRunner) bench(name string, bench_func fn (mut bench Benchmark, mut fixture Fixture) !) {
	mut fixture := b.create_or_reuse_fixture()

	mut bench := &Benchmark{
		name: name
	}
	b.benchmarks << bench
	bench_func(mut bench, mut fixture) or { println('Benchmark failed: ${err}') }
}
