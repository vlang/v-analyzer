// Copyright (c) 2022-2023 Petr Makhnev. All rights reserved.
// Use of this source code is governed by a MIT
// license that can be found in the LICENSE file.
module stubs

// This file contains definitions of compile time constants used in $if.
// Example:
// ```v
// $if linux {
//   println('linux') // this will be printed only if the current OS is Linux
// } $else $if windows {
//   println('windows') // this will be printed only if the current OS is Windows
// } $else {
//   println('other') // this will be printed if the current OS is neither Linux nor Windows
// }
// ```

// OSs

// windows set to `true` if the current OS is Windows.
pub const windows = false

// linux set to `true` if the current OS is Linux.
pub const linux = false

// macos set to `true` if the current OS is macOS.
pub const macos = false

// mac set to `true` if the current OS is macOS.
pub const mac = false

// darwin set to `true` if the current OS is macOS.
pub const darwin = false

// freebsd set to `true` if the current OS is FreeBSD.
pub const freebsd = false

// openbsd set to `true` if the current OS is OpenBSD.
pub const openbsd = false

// netbsd set to `true` if the current OS is NetBSD.
pub const netbsd = false

// serenity set to `true` if the current OS is Serenity.
pub const serenity = false

// vinix set to `true` if the current OS is Vinix.
pub const vinix = false

// ios set to `true` if the current OS is iOS.
pub const ios = false

// android set to `true` if the current OS is Android.
pub const android = false

// emscripten set to `true` if the current OS is Emscripten.
pub const emscripten = false

// js_node set to `true` if the current platform is Node.js.
pub const js_node = false

// js_freestanding set to `true` if the current platform is pure JavaScript.
pub const js_freestanding = false

// js_browser set to `true` if the current platform is JavaScript in a browser.
pub const js_browser = false

// js set to `true` if the current platform is JavaScript.
pub const js = false

// mach set to `true` if the current OS is Mach.
pub const mach = false

// dragonfly set to `true` if the current OS is Dragonfly.
pub const dragonfly = false

// gnu set to `true` if the current OS is GNU.
pub const gnu = false

// hpux set to `true` if the current OS is HP-UX.
pub const hpux = false

// haiku set to `true` if the current OS is Haiku.
pub const haiku = false

// qnx set to `true` if the current OS is QNX.
pub const qnx = false

// solaris set to `true` if the current OS is Solaris.
pub const solaris = false

// termux set to `true` if the current OS is Termux.
pub const termux = false

// Compilers

// gcc set to `true` if the current compiler is GCC.
pub const gcc = false

// tiny set to `true` if the current compiler is TinyCC.
pub const tiny = false

// clang set to `true` if the current compiler is Clang.
pub const clang = false

// mingw set to `true` if the current compiler is MinGW.
pub const mingw = false

// msvc set to `true` if the current compiler is MSVC.
pub const msvc = false

// cpp set to `true` if the current compiler is C++.
pub const cplusplus = false

// Platforms

// x86 set to `true` if the current platform is x86.
pub const amd64 = false

// arm set to `true` if the current platform is ARM.
pub const arm64 = false

// x64 set to `true` if the current platform is x64.
pub const x64 = false

// x32 set to `true` if the current platform is x32.
pub const x32 = false

// little_endian set to `true` if the current platform is little endian.
pub const little_endian = false

// big_endian set to `true` if the current platform is big endian.
pub const big_endian = false

// Other

// debug set to `true` if the -g flag is passed to the compiler.
pub const debug = false

// prod set to `true` if the -prod flag is passed to the compiler.
pub const prod = false

// test set to `true` file run with `v test`.
pub const test = false

// glibc set to `true` if the -glibc flag is passed to the compiler.
pub const glibc = false

// prealloc set to `true` if the -prealloc flag is passed to the compiler.
pub const prealloc = false

// no_bounds_checking set to `true` if the -no_bounds_checking flag is passed to the compiler.
pub const no_bounds_checking = false

// freestanding set to `true` if the -freestanding flag is passed to the compiler.
pub const freestanding = false

// no_segfault_handler set to `true` if the -no_segfault_handler flag is passed to the compiler.
pub const no_segfault_handler = false

// no_backtrace set to `true` if the -no_backtrace flag is passed to the compiler.
pub const no_backtrace = false

// no_main set to `true` if the -no_main flag is passed to the compiler.
pub const no_main = false
