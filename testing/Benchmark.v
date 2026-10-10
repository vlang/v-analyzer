module testing

import time

pub struct Benchmark {
mut:
	name  string
	watch time.StopWatch
}

pub fn (mut b Benchmark) start() {
	b.watch.start()
}

pub fn (mut b Benchmark) stop() {
	b.watch.stop()
}

pub fn (b &Benchmark) print_results() {
	println('Benchmark: ' + b.name)
	println('Time: ' + b.watch.elapsed().str())
}
