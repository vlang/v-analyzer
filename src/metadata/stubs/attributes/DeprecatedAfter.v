// Copyright (c) 2022-2023 Petr Makhnev. All rights reserved.
// Use of this source code is governed by a MIT
// license that can be found in the LICENSE file.
module attributes

// DeprecatedAfter attribute specifies a date, after which the element will be
// considered deprecated.
//
// Before that date, calls to the function (for example) will be compiler
// notices – you will see them, but the compilation is not affected.
//
// After that date, calls will become warnings, so ordinary compiling will still
// work, but compiling with `-prod` will not (all warnings are treated like errors with `-prod`).
//
// 6 months after the deprecation date, calls will be hard
// compiler errors.
//
// Note: Must be used with `deprecated` attribute!
//
// See also [deprecated](#Deprecated) attribute.
//
// Example:
// ```
// [deprecated: 'use `foo` instead']
// [deprecated_after: '2023-05-27']
// fn boo() {}
// ```
@[attribute]
pub struct DeprecatedAfter {
	name            string = 'deprecated_after'
	with_arg        bool   = true
	arg_is_optional bool
	target          []Target = [Target.struct_, Target.function, Target.field, Target.constant,
	Target.type_alias]
}
