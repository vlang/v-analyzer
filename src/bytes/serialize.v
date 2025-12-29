module bytes

pub struct Serializer {
pub mut:
	data []u8
}

@[inline]
pub fn (mut s Serializer) write_u8(data u8) {
	s.data << data
}

@[inline]
pub fn (mut s Serializer) write_string(str string) {
	s.write_int(str.len)
	unsafe { s.data.push_many(str.str, str.len) }
}

pub fn (mut s Serializer) write_int(data int) {
	if data > 0 && data < 0xff {
		s.data << 1
		s.data << u8(data)
		return
	}
	s.data << 0
	for i in 0 .. 4 {
		s.data << u8(data >> (8 * (3 - i))) & 0xff
	}
}

pub fn (mut s Serializer) write_i64(data i64) {
	for i in 0 .. 8 {
		s.data << u8(data >> (8 * (7 - i))) & 0xff
	}
}
