// Copyright (c) 2022-2023 Petr Makhnev. All rights reserved.
// Use of this source code is governed by a MIT
// license that can be found in the LICENSE file.
module attributes

// Noinit attribute mark struct.
// Such structs cannot be created in other modules through initialization (`Foo{}`).
// Instead, they must be initialized via a call to the constructor-like function, if any.
//
// This attribute is useful when you need to make sure that the structure is always created
// correctly and that all required fields are set.
@[attribute]
pub struct Noinit {
	name            string = 'noinit'
	with_arg        bool
	arg_is_optional bool
	target          []Target = [Target.struct_]
}
