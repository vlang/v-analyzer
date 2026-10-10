// Copyright (c) 2022-2023 Petr Makhnev. All rights reserved.
// Use of this source code is governed by a MIT
// license that can be found in the LICENSE file.
module attributes

// Json attribute specifies a custom field name when marshaled to JSON.
// This is useful when you need to use a field name that is not allowed in V.
// For example, you need to specify a PascalCase name for a field, V does not
// allow such a name for a field, in which case you can use the Json attribute.
//
// Example:
// ```v
// struct User {
// 	 first_name string [json: 'FirstName']
// }
@[attribute]
pub struct Json {
	name            string = 'json'
	with_arg        bool   = true
	arg_is_optional bool
	target          []Target = [Target.field]
}
