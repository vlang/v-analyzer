// Copyright (c) 2022-2023 Petr Makhnev. All rights reserved.
// Use of this source code is governed by a MIT
// license that can be found in the LICENSE file.
module attributes

// JsonAsNumber marks an enum.
// The fields of such enum will be encoded in JSON as numbers, not as strings
// with the field name.
//
// Example:
//
// ```
// [json_as_number]
// enum Color {
//   red = 1
//   green = 2
// }
//
// struct MyStruct {
//   color Color = .green
// }
//
// // JSON representation of MyStruct:
// // {
// //   "color": 2
// // }
//
// // JSON representation of MyStruct without the attribute:
// // {
// //   "color": "green"
// // }
// ```
@[attribute]
pub struct JsonAsNumber {
	name            string = 'json_as_number'
	with_arg        bool
	arg_is_optional bool
	target          []Target = [Target.enum_]
}
