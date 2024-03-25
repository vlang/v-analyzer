module bytes

pub struct Serializer {
pub mut:
	data []u8
}

pub fn (mut s Serializer) write_string(str string) {
	s.write_int(str.len)
	for sym in str {
		s.write_u8(sym)
	}
}

pub fn (mut s Serializer) write_int(data int) {
	if data > 0 && data < 0xFF {
		s.write_u8(1)
		s.write_u8(u8(data))
		return
	}

	s.write_u8(0)
	for i in 0 .. 4 {
		s.write_u8(u8(data >> (8 * (3 - i))) & 0xFF)
	}
}

pub fn (mut s Serializer) write_i64(data i64) {
	for i in 0 .. 8 {
		s.write_u8(u8(data >> (8 * (7 - i))) & 0xFF)
	}
}

@[inline]
pub fn (mut s Serializer) write_u8(data u8) {
	s.data << data
}
