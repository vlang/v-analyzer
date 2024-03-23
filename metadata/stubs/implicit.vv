// Copyright (c) 2022-2023 Petr Makhnev. All rights reserved.
// Use of this source code is governed by a MIT
// license that can be found in the LICENSE file.
module stubs

// Any is any type in code.
//
// It is needed to define all implicit methods of all types.
type Any = any

// str returns a string representation of the type.
//
// **Note**
//
// This method is implicitly implemented by any type,
// you can override it for your type:
// ```
// struct MyStruct {
//   name string
// }
//
// pub fn (s MyStruct) str() string {
//   return s.name
// }
// ```
//
// Example:
//
// ```
// struct Foo {}
//
// fn main() {
//   s := Foo{}
//   println(s.str()) // Foo{}
//
//   mp := map[string]int{}
//   println(mp.str()) // map[string]int{}
// }
// ```
pub fn (a Any) str() string

// FlagEnum describes a enum with `[flag]` attribute.
//
// See [Flag](#flag) attribute for detail.
pub enum FlagEnum {}

// has checks if the enum value has the passed flag.
//
// Example:
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
//   assert p.has(.read) // test if p has read flag
//   assert p.has(.read | .other) // test if *at least one* of the flags is set
// }
// ```
pub fn (f FlagEnum) has(flag FlagEnum) bool

// all checks if the enum value has all passed flags.
//
// Example:
// ```
// [flag]
// enum Permissions {
//   read  // = 0b0001
//   write // = 0b0010
//   other // = 0b0100
// }
//
// fn main() {
//   p := Permissions.read | .write
//   assert p.all(.read | .write) // test if *all* of the flags is set
// }
// ```
pub fn (f FlagEnum) all(flag FlagEnum) bool

// set sets the passed flags.
// If the flag is already set, it will be ignored.
//
// Example:
// ```
// [flag]
// enum Permissions {
//   read  // = 0b0001
//   write // = 0b0010
//   other // = 0b0100
// }
//
// fn main() {
//   mut p := Permissions.read
//   p.set(.write)
//   assert p.has(.write)
// }
// ```
pub fn (f FlagEnum) set(flag FlagEnum)

// toggle toggles the passed flags.
// If the flag is already set, it will be unset.
// If the flag is not set, it will be set.
//
// Example:
// ```
// [flag]
// enum Permissions {
//   read  // = 0b0001
//   write // = 0b0010
//   other // = 0b0100
// }
//
// fn main() {
//   mut p := Permissions.read
//   p.toggle(.read)
//   assert !p.has(.read)
// }
// ```
pub fn (f FlagEnum) toggle(flag FlagEnum)

// clear clears the passed flags.
// If the flag is not set, it will be ignored.
//
// Example:
// ```
// [flag]
// enum Permissions {
//   read  // = 0b0001
//   write // = 0b0010
//   other // = 0b0100
// }
//
// fn main() {
//   mut p := Permissions.read
//   p.clear(.read)
//   assert !p.has(.read)
// }
// ```
pub fn (f FlagEnum) clear(flag FlagEnum)
