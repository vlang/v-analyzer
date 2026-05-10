module loglib

import io
import time

@[inline]
pub fn log(level LogLevel, msg ...string) {
	logger.log(level, ...msg)
}

@[inline]
pub fn log_one(level LogLevel, msg string) {
	logger.log(level, msg)
}

@[inline]
pub fn warn(msg ...string) {
	logger.log(.warn, ...msg)
}

@[inline]
pub fn info(msg ...string) {
	logger.log(.info, ...msg)
}

@[inline]
pub fn trace(msg ...string) {
	logger.log(.trace, ...msg)
}

@[inline]
pub fn error(msg ...string) {
	logger.log(.error, ...msg)
}

@[inline]
pub fn set_level(level LogLevel) {
	logger.set_level(level)
}

@[inline]
pub fn set_flush_rate(dur time.Duration) {
	logger.flush_rate = dur
}

@[inline]
pub fn set_output(out io.Writer) {
	logger.set_output(out)
}

@[inline]
pub fn get_output() io.Writer {
	return logger.get_output()
}

@[inline]
pub fn with_fields(fields Fields) &Entry {
	return logger.with_fields(fields)
}

@[inline]
pub fn with_duration(dur time.Duration) &Entry {
	return logger.with_duration(dur)
}

@[inline]
pub fn with_gc_heap_usage(usage GCHeapUsage) &Entry {
	return logger.with_gc_heap_usage(usage)
}
