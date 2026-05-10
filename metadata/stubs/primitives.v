// Copyright (c) 2022-2023 Petr Makhnev. All rights reserved.
// Use of this source code is governed by a MIT
// license that can be found in the LICENSE file.
module stubs

// This file contains definitions of primitive types V.

// bool is the set of boolean values, true and false.
pub type bool = bool

// u8 is the set of all unsigned 8-bit integers.
// Range: 0 through 255.
pub type u8 = u8

// u16 is the set of all unsigned 16-bit integers.
// Range: 0 through 65535.
pub type u16 = u16

// u32 is the set of all unsigned 32-bit integers.
// Range: 0 through 4294967295.
pub type u32 = u32

// u64 is the set of all unsigned 64-bit integers.
// Range: 0 through 18446744073709551615.
pub type u64 = u64

// usize is platform-dependent unsigned integer type.
pub type usize = u64

// i8 is the set of all signed 8-bit integers.
// Range: -128 through 127.
pub type i8 = i8

// i16 is the set of all signed 16-bit integers.
// Range: -32768 through 32767.
pub type i16 = i16

// i32 is the set of all signed 32-bit integers.
// Range: -2147483648 through 2147483647.
pub type i32 = int

// int is the set of all signed 32-bit integers.
// Range: -2147483648 through 2147483647.
pub type int = int

// i64 is the set of all signed 64-bit integers.
// Range: -9223372036854775808 through 9223372036854775807.
pub type i64 = i64

// isize is a signed integer type, whose size varies, and is 32bit on 32bit platforms, or 64bit on 64bit platforms.
pub type isize = i64

// usize is an unsigned integer type, whose size varies and is 32bit on 32bit platforms, or 64bit on 64bit platforms.
pub type usize = u64

// f32 is the set of all IEEE-754 32-bit floating-point numbers.
pub type f32 = f32

// f64 is the set of all IEEE-754 64-bit floating-point numbers.
pub type f64 = f64

// byte is an alias for u8 and is equivalent to u8 in all ways.
// Do not use `byte` in new code, use `u8` instead.
pub type byte = u8

// rune is used, for representing individual Unicode codepoints. It is 32bit sized.
pub type rune = u32

// char is similar to u8, it is mostly used for [C interoperability](https://docs.vosca.dev/advanced-concepts/v-and-c.html).
// In C, the type `char` can be signed or unsigned, depending on platform.
pub type char = u8

// voidptr is an untyped pointer. You can pass any other type of pointer value, to a function that accepts a voidptr.
// Mostly used for [C interoperability](https://docs.vosca.dev/advanced-concepts/v-and-c.html).
pub type voidptr = voidptr

// byteptr is a pointer to bytes. Deprecated. Use `&u8` instead in new code.
// Mostly used for [C interoperability](https://docs.vosca.dev/advanced-concepts/v-and-c.html).
pub type byteptr = byteptr

// charptr is a pointer to chars.
// Mostly used for [C interoperability](https://docs.vosca.dev/advanced-concepts/v-and-c.html).
pub type charptr = charptr
