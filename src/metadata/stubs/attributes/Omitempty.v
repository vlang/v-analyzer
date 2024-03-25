// Copyright (c) 2022-2023 Petr Makhnev. All rights reserved.
// Use of this source code is governed by a MIT
// license that can be found in the LICENSE file.
module attributes

// Omitempty attribute marks field as omitempty.
// When field is omitempty, it will be omitted when marshaling to JSON if its value is empty.
@[attribute]
pub struct Omitempty {
	name            string = 'omitempty'
	with_arg        bool
	arg_is_optional bool
	target          []Target = [Target.field]
}
