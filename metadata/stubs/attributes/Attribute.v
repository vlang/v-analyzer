// Copyright (c) 2022-2023 Petr Makhnev. All rights reserved.
// Use of this source code is governed by a MIT
// license that can be found in the LICENSE file.
module attributes

// Note: this is not an official attribute syntax, V does not provide
// any official way to define attributes. This is used only for
// documentation purposes.

// Target describes the possible places where the attribute is allowed.
enum Target {
	function
	field
	struct_
	enum_
	constant
	type_alias
}

// Attribute is base interface that describes the
// information and behavior of any attribute.
interface Attribute {
	name            string   // name of the attribute
	with_arg        bool     // whether the attribute has an argument
	arg_is_optional bool     // if with_arg is true, this field is used to indicate whether the argument is optional
	target          []Target // places where the attribute is allowed
}
