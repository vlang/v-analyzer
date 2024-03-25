// Copyright (c) 2022-2023 Petr Makhnev. All rights reserved.
// Use of this source code is governed by a MIT
// license that can be found in the LICENSE file.
module attributes

// Noreturn attribute marks a function as not return to its caller.
//
// Such functions can be used at the end of or blocks, just like
// [`exit`](#exit) or [`panic`](#panic).
//
// Such functions can not have return types, and should end either in `for {}`, or
// by calling other `[noreturn]` functions.
//
// Example:
//
// ```
// [noreturn]
// fn redirect() {
//    // do something
//    exit(1)
// }
//
// fn main() {
//     if condition {
//         redirect();
//         // unreachable
//     }
// }
// ```
@[attribute]
pub struct Noreturn {
	name            string = 'noreturn'
	with_arg        bool
	arg_is_optional bool
	target          []Target = [Target.function]
}
