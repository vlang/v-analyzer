// Copyright (c) 2022-2023 Petr Makhnev. All rights reserved.
// Use of this source code is governed by a MIT
// license that can be found in the LICENSE file.
module stubs

// This file contains definitions of compile time functions and constants.

import v.embed_file { EmbedFileData }

// @FN replaced with the name of the current V function.
pub const @FN = ''

// @METHOD replaced with name of the current V method and receiver type: `ReceiverType.MethodName`.
pub const @METHOD = ''

// @MOD replaced with the name of the current V module.
pub const @MOD = ''

// @STRUCT  replaced with the name of the current V struct.
pub const @STRUCT = ''

// @FILE replaced with the absolute path of the V source file.
pub const @FILE = ''

// @LINE replaced with the V line number where it appears (as a string).
pub const @LINE = ''

// @FILE_LINE replaced with `@FILE:@LINE`, but the file part is a relative path.
pub const @FILE_LINE = ''

// @COLUMN replaced with the column where it appears (as a string).
pub const @COLUMN = ''

// @VEXE replaced with the path to the V compiler.
pub const @VEXE = ''

// @VEXEROOT replaced with the folder, where the V executable is.
pub const @VEXEROOT = ''

// @VHASH replaced with the shortened commit hash of the V compiler.
pub const @VHASH = ''

// @VMOD_FILE replaced with the contents of the nearest v.mod file.
pub const @VMOD_FILE = ''

// @VMODROOT replaced with the folder, where the nearest v.mod file is.
pub const @VMODROOT = ''

// CompressionType is the type of compression used for the embedded file.
// See [$embed_file] for more details.
pub enum CompressionType {
	zlib
}

// $embed_file embed a file in a binary.
//
// Passed file path can be absolute or relative.
//
// When the program is compiled without the `-prod` flag, the file will not be embedded. Instead,
// it will be loaded the first time your program calls
//
//
// When you compile with -prod, the file will be embedded inside your executable,
// increasing your binary size, but making it more self contained and thus easier
// to distribute.
// In this case, `embedded_file.data()` will cause no IO, and it will always return the same data.
//
// `$embed_file` supports compression of the embedded file when compiling with `-prod`.
// Currently only one compression type is supported: `zlib`. See [CompressionType](CompressionType) for more details.
//
// Example:
// ```
// embedded_file := $embed_file('v.png', .zlib) // compressed using zlib
// data := embedded_file.data() // get data as a u8 array
// path := embedded_file.path // get path to the file
// ```
pub fn $embed_file(path string, compression_type CompressionType) EmbedFileData

// $tmpl embed and parse template file.
//
// Passed file path can be absolute or relative.
//
// `$tmpl` compiles an template into V during compilation, and embeds the resulting
// code into the current function. That means that the template automatically has
// access to that function's entire environment (like variables).
//
// See [Template documentation](https://docs.vosca.dev/concepts/templates/overview.html) for more details.
//
// Example:
// ```
// fn build() string {
//   name := 'Peter'
//   age := 25
//   numbers := [1, 2, 3]
//   return $tmpl('template.txt')
// }
// ```
pub fn $tmpl(path string) string

// $env obtain the value of the environment variable with passed name at compile time.
//
// Example:
// ```
// println($env('HOME'))
// ```
pub fn $env(name string) string

// $compile_error causes a compile error with the passed message.
//
// Example:
// ```
// $if windows {
//   $compile_error('Windows is not supported')
// }
// ```
@[noreturn]
pub fn $compile_error(msg string)

// $compile_warn causes a compile warning with the passed message.
//
// Example:
// ```
// $if windows {
//   $compile_warn('Windows is not fully supported')
// }
// ```
pub fn $compile_warn(msg string)

// _likely_ is a hint to the compiler that the passed expression is **likely to be true**,
// so it can generate assembly code, with less chance of
// [branch misprediction](https://en.wikipedia.org/wiki/Branch_predictor).
//
// Example:
// ```
// if _likely_(x > 0) {
//   // code
// }
// ```
//
// In a non-C backend, it is ignored.
pub fn _likely_(typ bool) bool

// _unlikely_ is a hint to the compiler that the passed expression is **highly improbable**.
// See also [branch predictor](https://en.wikipedia.org/wiki/Branch_predictor).
//
// Example:
// ```
// if _unlikely_(x < 0) {
//   // code
// }
// ```
//
// In a non-C backend, it is ignored.
pub fn _unlikely_(typ bool) bool
