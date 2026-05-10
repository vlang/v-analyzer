module loglib

import strings
import term

pub struct TextFormatter {
mut:
	is_terminal bool
	initialized bool
}

fn (mut t TextFormatter) init(entry &Entry) {
	t.is_terminal = check_if_terminal(entry.logger.out)
}

fn (mut t TextFormatter) format(entry &Entry) ![]u8 {
	if !t.initialized {
		t.init(entry)
		t.initialized = true
	}

	mut sb := strings.new_builder(10)

	sb.write_string(t.colorize(entry, entry.time.format_ss(), term.gray))
	sb.write_string(' ')
	t.format_level(entry, mut sb)
	sb.write_string(' ')
	t.format_message(entry, mut sb)
	t.format_fields(entry, mut sb)
	sb.write_string('\n')

	return sb
}

fn (t &TextFormatter) format_level(entry &Entry, mut sb strings.Builder) {
	level := entry.level
	level_label := level.label()
	colored := t.colorize(entry, '[${level_label}]', t.level_color(level))
	sb.write_string(colored)

	if level in [.info, .warn] {
		sb.write_string(' ')
	}
}

fn (t &TextFormatter) format_message(entry &Entry, mut sb strings.Builder) {
	mut message := entry.message

	if message.len < 35 && entry.fields.len != 0 {
		message = message + ' '.repeat(35 - message.len)
	}

	sb.write_string(message)
}

fn (t &TextFormatter) format_fields(entry &Entry, mut sb strings.Builder) {
	fields := entry.fields
	if fields.len == 0 {
		return
	}

	level_color := t.level_color(entry.level)
	sb.write_string(' ')

	mut index := 0
	for key, field in fields {
		sb.write_string(t.colorize(entry, key, level_color))
		sb.write_string('=')
		sb.write_string(field)

		if index <= fields.len - 1 {
			sb.write_string(' ')
		}
		index++
	}
}

fn (t &TextFormatter) colorize(entry &Entry, msg string, fun fn (msg string) string) string {
	if !support_colors || entry.logger.color_mode == .never || !t.is_terminal {
		return msg
	}

	return fun(msg)
}

@[inline]
fn (_ &TextFormatter) level_color(level LogLevel) fn (msg string) string {
	return match level {
		.panic { term.red }
		.fatal { term.red }
		.error { term.red }
		.warn { term.yellow }
		.info { term.gray }
		.debug { term.gray }
		.trace { term.gray }
	}
}
