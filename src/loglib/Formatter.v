module loglib

pub interface Formatter {
mut:
	format(entry &Entry) ![]u8
}
