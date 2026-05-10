// Copyright (c) 2022-2023 Petr Makhnev. All rights reserved.
// Use of this source code is governed by a MIT
// license that can be found in the LICENSE file.
module stubs

// This file contains stubs for the vweb module.

import vweb

struct VWebTemplate {}

// html method renders a template.
// See documentation for [$vweb]($vweb) for more information.
pub fn (v VWebTemplate) html() vweb.Result

// $vweb constant allows you to render HTML template in endpoint functions.
//
// `$vweb.html()` in method like `<folder>_<name>() vweb.Result`
// render the `<name>.html` in folder `./templates/<folder>`
//
// `$vweb.html()` compiles an HTML template into V during compilation, and
// embeds the resulting code into the current function.
// That means that the template automatically has access to that
// function's entire environment (like variables).
//
// See [vweb documentation](https://modules.vosca.dev/standard_library/vweb.html) for more information.
//
// Example:
// ```
// ['/']
// pub fn (mut app App) page_home() vweb.Result {
//   // will render `./templates/page/home.html`
//   return $vweb.html()
// }
// ```
pub const $vweb = VWebTemplate{}
