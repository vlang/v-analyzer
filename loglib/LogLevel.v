module loglib

pub enum LogLevel {
	panic
	fatal
	error
	warn
	info
	debug
	trace
}

fn (l LogLevel) label() string {
	return match l {
		.panic { 'PANIC' }
		.fatal { 'FATAL' }
		.error { 'ERROR' }
		.warn { 'WARN' }
		.info { 'INFO' }
		.debug { 'DEBUG' }
		.trace { 'TRACE' }
	}
}
