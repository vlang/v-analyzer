module index

import time

// IndexNotFoundError is returned if the index is not found.
pub struct IndexNotFoundError {
	Error
}

// NeedReindexedError is returned if the index needs to be rebuilt.
pub struct NeedReindexedError {
	Error
}

// IndexVersionMismatchError is returned if the index version does not match the latest.
pub struct IndexVersionMismatchError {
	Error
}

// Index encapsulates the index storage logic.
pub struct Index {
pub:
	version string = '33'
pub mut:
	updated_at time.Time // time of last index update
	per_file   PerFileIndex
}

// decode encapsulates the index decoding logic.
// If the index was corrupted and could not be decoded, an error is returned.
// If the index version does not match the latest, an `IndexVersionMismatchError` is returned.
pub fn (mut i Index) decode(data []u8) ! {
	mut d := new_index_deserializer(data)
	index := d.deserialize_index(i.version)!
	i.per_file = index.per_file
}

// encode encapsulates the logic for encoding an index.
pub fn (i &Index) encode() []u8 {
	mut s := IndexSerializer{}
	s.serialize_index(i)
	return s.s.data
}
