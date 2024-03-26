@[translated]
module loglib

import term
import io
import os
import time

__global logger = Logger{
	formatter: TextFormatter{}
	out: os.stderr()
}

pub const support_colors = term.can_show_color_on_stderr() && term.can_show_color_on_stdout()

@[heap]
pub struct Logger {
mut:
	disabled   bool
	color_mode ColorMode

	formatter  Formatter
	out        io.Writer
	last_flush time.Time
	flush_rate time.Duration = 5 * time.second

	level u64 = u64(LogLevel.info)
}

@[inline]
pub fn (mut l Logger) disable() {
	l.disabled = true
}

@[inline]
pub fn (mut l Logger) enable() {
	l.disabled = false
}

@[inline]
pub fn (mut l Logger) use_color_mode(mode ColorMode) {
	l.color_mode = mode
}

@[inline]
pub fn (mut l Logger) use_color_mode_string(mode string) {
	enum_value := get_color_mode_by_name(mode) or { .auto }
	l.color_mode = enum_value
}

@[inline]
pub fn (l &Logger) level() u64 {
	return l.level
}

@[inline]
pub fn (mut l Logger) set_level(level LogLevel) {
	l.level = u64(level)
}

@[inline]
pub fn (mut l Logger) set_flush_rate(dur time.Duration) {
	l.flush_rate = dur
}

@[inline]
pub fn (mut l Logger) set_output(out io.Writer) {
	l.out = out
}

@[inline]
pub fn (mut l Logger) get_output() io.Writer {
	return l.out
}

@[inline]
pub fn (l &Logger) is_level_enabled(level LogLevel) bool {
	return l.level() >= u64(level)
}

pub fn (l &Logger) log(level LogLevel, msg ...string) {
	if !l.is_level_enabled(level) {
		return
	}

	entry := new_entry(l)
	entry.log(level, ...msg)
}

@[inline]
pub fn (mut l Logger) with_fields(fields Fields) &Entry {
	entry := new_entry(l)
	return entry.with_fields(fields)
}

@[inline]
pub fn (mut l Logger) with_duration(dur time.Duration) &Entry {
	entry := new_entry(l)
	return entry.with_duration(dur)
}

@[inline]
pub fn (mut l Logger) with_gc_heap_usage(usage GCHeapUsage) &Entry {
	entry := new_entry(l)
	return entry.with_gc_heap_usage(usage)
}
