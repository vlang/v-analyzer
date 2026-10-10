// Copyright (c) 2022-2023 Petr Makhnev. All rights reserved.
// Use of this source code is governed by a MIT
// license that can be found in the LICENSE file.
module attributes

// Heap attribute mark struct as always heap-allocated,
// so any struct creation will happen on the heap.
@[attribute]
pub struct Heap {
	name            string = 'heap'
	with_arg        bool
	arg_is_optional bool
	target          []Target = [Target.struct_]
}
