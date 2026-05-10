// Copyright (c) 2022-2023 Petr Makhnev. All rights reserved.
// Use of this source code is governed by a MIT
// license that can be found in the LICENSE file.
module attributes

// Table attribute sets a custom table name (case-sensitive).
// By default ORM uses default struct name.
@[attribute]
pub struct Table {
	name            string = 'table'
	with_arg        bool   = true
	arg_is_optional bool
	target          []Target = [Target.struct_]
}
