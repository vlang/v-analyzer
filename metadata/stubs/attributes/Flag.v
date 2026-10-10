// Copyright (c) 2022-2023 Petr Makhnev. All rights reserved.
// Use of this source code is governed by a MIT
// license that can be found in the LICENSE file.
module attributes

// Flag attribute mark enum as bitfield.
//
// Example:
// ```
// [flag]
// enum Permissions {
//   read  // = 0b0001
//   write // = 0b0010
//   other // = 0b0100
// }
// ```
//
// Here, each subsequent element will increase the value of the previous one
// by shifting to the left.
//
// For an enum with a flag attribute, the special methods `has()` and `all()` can be used.
//
// ```
// [flag]
// enum Permissions {
//   read  // = 0b0001
//   write // = 0b0010
//   other // = 0b0100
// }
//
// fn main() {
//   p := Permissions.read
//   assert p.has(.read | .other) // test if *at least one* of the flags is set
//
//   p1 := Permissions.read | .write
//   assert p1.has(.write)
//   assert p1.all(.read | .write) // test if *all* of the flags is set
// }
// ```
@[attribute]
pub struct Flag {
	name            string = 'flag'
	with_arg        bool
	arg_is_optional bool
	target          []Target = [Target.enum_]
}
