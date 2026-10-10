module stubs

type placeholder = any

// TypeInfo describe type information returned by the [typeof](#$typeof) builtin function.
pub struct TypeInfo {
pub mut:
	idx  int    // index of the type in the type table
	name string // name of the type
}

// $offsetof returns the offset of the field with passed name in the passed struct.
//
// Example:
// ```
// struct Foo {
//    a int
//    b string
// }
//
// assert __offsetof(Foo, b) == 8
// ```
pub fn $offsetof(struct_type placeholder, field_name placeholder) int

// $isreftype returns true if the type is a reference type.
//
// This builtin function can be used in two ways:
// 1. `isreftype[type]()` – check passed type
// 2. `isreftype(expr)` – check type of passed expression
//
// Examples:
// ```
// assert isreftype[int]() == false
// assert isreftype[string]() == true
// assert isreftype[[]int]() == true
// assert isreftype[map[string]int]() == true
// assert isreftype('hello') == true
// assert isreftype(10) == true
// ```
pub fn $isreftype[T](typ T) bool

// $sizeof returns the size of a type in bytes.
//
// This builtin function can be used in two ways:
//
// 1. `sizeof[type]()` – returns the size of the type in bytes
// 2. `sizeof(expr)` – returns the size of the type of the expression in bytes
//
// The size of a type is the number of bytes it occupies in memory.
//
// Example:
// ```
// assert sizeof[i64]() == 8
// assert sizeof[[]int]() == 32
// assert sizeof('hello') == 16
// assert sizeof(i64(100)) == 8
// assert sizeof(true) == 1
// ```
pub fn $sizeof[T](typ T) int

// $typeof returns the [TypeInfo](#TypeInfo) of the given expression.
//
// Example:
// ```
// type StringOrInt = string | int
//
// fn foo(x StringOrInt) {
//   if typeof(x).name == 'string' {
//     println('x is a string')
//   }
// }
//
pub fn $typeof[T](typ T) TypeInfo

// $dump prints the given expression with position of `dump()` call.
//
// Example:
// ```
// name := 'John'
// dump(name)
// ```
// Output:
// ```
// [/Users/petrmakhnev/intellij-v/main.v:2] name: John
// ```
pub fn $dump[T](typ T) T
