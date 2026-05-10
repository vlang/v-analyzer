// Copyright (c) 2023 Petr Makhnev. All rights reserved.
// Use of this source code is governed by a MIT
// license that can be found in the LICENSE file.
module stubs

// This file contains definitions of compile time reflection.

// $int describes any integer type.
//
// Example:
// ```
// $for f in Test.fields {
//   $if f.typ is $int {
//     println(f.name)
//   }
// }
// ```
pub const $int = TypeInfo{}

// $float describes any float type.
//
// Example:
// ```
// $for f in Test.fields {
//   $if f.typ is $float {
//     println(f.name)
//   }
// }
// ```
pub const $float = TypeInfo{}

// $array describes any array type.
//
// Example:
// ```
// $for f in Test.fields {
//   $if f.typ is $array {
//     println(f.name)
//   }
// }
// ```
pub const $array = TypeInfo{}

// $map describes any map type.
//
// Example:
// ```
// $for f in Test.fields {
//   $if f.typ is $map {
//     println(f.name)
//   }
// }
// ```
pub const $map = TypeInfo{}

// $struct describes any struct type.
//
// Example:
// ```
// $for f in Test.fields {
//   $if f.typ is $struct {
//     println(f.name)
//   }
// }
// ```
pub const $struct = TypeInfo{}

// $interface describes any interface type.
//
// Example:
// ```
// $for f in Test.fields {
//   $if f.typ is $interface {
//     println(f.name)
//   }
// }
// ```
pub const $interface = TypeInfo{}

// $enum describes any enum type.
//
// Example:
// ```
// $for f in Test.fields {
//   $if f.typ is $enum {
//     println(f.name)
//   }
// }
// ```
pub const $enum = TypeInfo{}

// $alias describes any alias type.
//
// Example:
// ```
// $for f in Test.fields {
//   $if f.typ is $alias {
//     println(f.name)
//   }
// }
// ```
pub const $alias = TypeInfo{}

// $sumtype describes any sumtype type.
//
// Example:
// ```
// $for f in Test.fields {
//   $if f.typ is $sumtype {
//     println(f.name)
//   }
// }
// ```
pub const $sumtype = TypeInfo{}

// $function describes any function type.
//
// Example:
// ```
// $for f in Test.fields {
//   $if f.typ is $function {
//     println(f.name)
//   }
// }
// ```
pub const $function = TypeInfo{}

// $option describes any option type.
//
// Example:
// ```
// $for f in Test.fields {
//   $if f.typ is $option {
//     println(f.name)
//   }
// }
// ```
pub const $option = TypeInfo{}

struct CompileTimeTypeInfo {
pub:
	// fields describes the list of structure fields.
	// This field can only be used inside `$for`.
	//
	// Example:
	// ```v
	// struct Foo {
	//   a int
	//   b string
	// }
	//
	// fn main() {
	//   $for field in Foo.fields {
	//     println(field.name)
	//   }
	// }
	// ```
	fields []FieldData
}
