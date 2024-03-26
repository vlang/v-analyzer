module bytes

pub struct Deserializer {
mut:
	index int
	data  []u8
}

pub fn new_deserializer(data []u8) Deserializer {
	return Deserializer{
		data: data
	}
}

pub fn (mut s Deserializer) read_string() string {
	len := s.read_int()
	if len == 0 {
		return ''
	}

	data := s.data[s.index..s.index + len]
	s.index += len
	return data.bytestr()
}

pub fn (mut s Deserializer) read_int() int {
	first := s.read_u8()
	if first == 1 {
		return s.read_u8()
	}

	data := s.data[s.index..s.index + 4]
	s.index += 4
	mut res := 0
	for index, datum in data {
		res |= datum << (8 * (3 - index))
	}
	return res
}

pub fn (mut s Deserializer) read_i64() i64 {
	data := s.data[s.index..s.index + 8]
	s.index += 8
	mut res := 0
	for index, datum in data {
		res |= datum << (8 * (7 - index))
	}
	return res
}

@[inline]
pub fn (mut s Deserializer) read_u8() u8 {
	index := s.index
	s.index++
	return s.data[index]
}
