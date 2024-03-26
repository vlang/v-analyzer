// Copyright (c) 2022-2023 Petr Makhnev. All rights reserved.
// Use of this source code is governed by a MIT
// license that can be found in the LICENSE file.
module attributes

// Manualfree attribute marks a function and the autofree engine
// will not automatically clear the memory allocated in that function.
//
// You will need to free any memory allocated in this function yourself.
@[attribute]
pub struct Manualfree {
	name            string = 'manualfree'
	with_arg        bool
	arg_is_optional bool
	target          []Target = [Target.function]
}
