module loglib

import time
import os

pub type Fields = map[string]string

pub struct Entry {
pub mut:
	logger  &Logger
	fields  Fields
	time    time.Time
	level   LogLevel
	message string
}

pub fn new_entry(logger &Logger) &Entry {
	return &Entry{
		logger: logger
	}
}

pub fn (entry &Entry) clone() &Entry {
	return &Entry{
		logger: entry.logger
		fields: entry.fields.clone()
		time: entry.time
		level: entry.level
		message: entry.message
	}
}

pub fn (entry &Entry) with_fields(fields Fields) &Entry {
	mut own_fields := entry.fields.clone()
	for k, v in fields {
		own_fields[k] = v
	}

	return &Entry{
		logger: entry.logger
		fields: own_fields
		time: entry.time
		level: entry.level
		message: entry.message
	}
}

pub fn (entry &Entry) with_duration(dur time.Duration) &Entry {
	return entry.with_fields({
		'duration': dur.str()
	})
}

pub fn (entry &Entry) with_gc_heap_usage(usage GCHeapUsage) &Entry {
	return entry.with_fields({
		'heap_size':      usage.heap_size.str()
		'free_bytes':     usage.free_bytes.str()
		'total_bytes':    usage.total_bytes.str()
		'unmapped_bytes': usage.unmapped_bytes.str()
		'bytes_since_gc': usage.bytes_since_gc.str()
	})
}

pub fn (entry &Entry) error(msg ...string) {
	entry.log(.error, ...msg)
}

pub fn (entry &Entry) warn(msg ...string) {
	entry.log(.warn, ...msg)
}

pub fn (entry &Entry) info(msg ...string) {
	entry.log(.info, ...msg)
}

pub fn (entry &Entry) trace(msg ...string) {
	entry.log(.trace, ...msg)
}

pub fn (entry &Entry) log(level LogLevel, msg ...string) {
	if !entry.logger.is_level_enabled(level) {
		return
	}
	entry.log_impl(level, ...msg)
}

pub fn (entry &Entry) log_one(level LogLevel, msg string) {
	entry.log(level, msg)
}

pub fn (entry &Entry) log_impl(level LogLevel, msg ...string) {
	mut new_entry := entry.clone()
	new_entry.time = time.now()
	new_entry.level = level
	new_entry.message = msg.join(' ')

	new_entry.write()

	if u64(level) <= u64(LogLevel.panic) {
		panic(new_entry)
	}
}

fn (mut entry Entry) write() {
	formatted := entry.logger.formatter.format(entry) or {
		eprintln('failed to format log message: ${err}')
		return
	}

	entry.logger.out.write(formatted) or {
		eprintln('failed to write log message: ${err}')
		return
	}

	if time.since(entry.logger.last_flush) > entry.logger.flush_rate {
		mut out := entry.logger.out
		if mut out is os.File {
			out.flush()
		}

		entry.logger.last_flush = time.now()
	}
}
