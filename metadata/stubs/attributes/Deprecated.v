// Copyright (c) 2022-2023 Petr Makhnev. All rights reserved.
// Use of this source code is governed by a MIT
// license that can be found in the LICENSE file.
module attributes

// Deprecated attribute mark declaration as deprecated.
// Only *direct* accesses to element in *other modules*, will produce deprecation notices/warnings.
// Optionally, a message can be provided. Format of the message is as follows:
//
// ```
// use <new element name> instead
// use <new element name> instead: <additional message>
// ```
//
// See also [deprecated_after](#DeprecatedAfter) attribute.
//
// Example:
// ```
// [deprecated: 'use foo() instead']
// fn boo() {}
// ```
// ```
// [deprecated: 'use foo() instead: boo() has some issues']
// fn boo() {}
// ```
@[attribute]
pub struct Deprecated {
	name            string   = 'deprecated'
	with_arg        bool     = true
	arg_is_optional bool     = true
	target          []Target = [Target.struct_, Target.function, Target.field, Target.constant,
	Target.type_alias]
}
