<img width="200px" src="./docs/cover-light.png#gh-light-mode-only">
<img width="200px" src="./docs/cover-dark.png#gh-dark-mode-only">

# v-analyzer

[![][badge__vscode_ext]](https://marketplace.visualstudio.com/items?itemName=VOSCA.vscode-v-analyzer)
[![][badge__build_ci]](https://github.com/vlang/v-analyzer/actions/workflows/build_ci.yml?query=branch%3Amain)
[![][badge__tests_ci]](https://github.com/vlang/v-analyzer/actions/workflows/analyzer_tests.yml?query=branch%3Amain)
[![][badge__tree_sitter_ci]](https://github.com/vlang/v-analyzer/actions/workflows/test_tree_sitter_v.yml?query=branch%3Amain)
[![][badge__vscode_ext_ci]](https://github.com/vlang/v-analyzer/actions/workflows/vscode_extension_tests.yml?query=branch%3Amain)

Bring IDE features for the V programming language to VS Code, Vim, and other editors.

v-analyzer provides the following features:

- code completion/IntelliSense
- go to definition, type definition
- find all references, document symbol, symbol renaming
- types and documentation on hover
- inlay hints for types and some construction like `or` block
- semantic syntax highlighting
- formatting
- signature help

## Installation

### Linux and macOS

```sh
v -e "$(curl -fsSL https://raw.githubusercontent.com/vlang/v-analyzer/main/install.vsh)"
```

### Windows

The install.vsh file is downloaded to the current directory and stored there temporarily.
So make sure that there is no file with this name or that it is safe when it is
overwritten or deleted.

#### Powershell

```sh
curl -o install.vsh https://raw.githubusercontent.com/vlang/v-analyzer/main/install.vsh; v run install.vsh; del install.vsh
```

#### Command shell

```sh
curl -o install.vsh https://raw.githubusercontent.com/vlang/v-analyzer/main/install.vsh && v run install.vsh && del install.vsh
```

## Pre-built binaries

You can download pre-built binaries from the
[release page](https://github.com/vlang/v-analyzer/releases).
Currently, we provide binaries for Linux (x64), macOS (x64 and ARM), and Windows (x64).

## Building from source

> **Note**
> This repository uses Git submodules.
> In practice, this means that you either have to:
> `git clone --filter=blob:none --recursive --shallow-submodules https://github.com/vlang/v-analyzer`
> ... or, if you used just `git clone https://github.com/vlang/v-analyzer`, you have to later do:
> `git submodule init`
> `git submodule update`
> inside your local `v-analyzer` clone.
> If you do not do either, the symptom is that when you try to build v-analyzer, you will get a
> C compiler message, about `lib.c not found`

> **Note**
> If you're using Windows, then you need GCC for any build, as TCC doesn't work
> due to some issues.

Update V to the latest version:

```bash
v up
```

Install dependencies:

```bash
v install
```

You can build debug or release version of the binary.
Debug version will be slower, but faster to compile.

Debug build:

```bash
v build.vsh debug
```

Release build:

```bash
v build.vsh release
```

Binary will be placed in `bin/` folder.

## Setup

Add `bin/` folder to your `$PATH` environment variable to use `v-analyzer`
command inside VS Code and other editors (**preferred**).

Or, you can specify the path to the binary in your VS Code settings:

```json
{
  "v-analyzer.serverPath": "/path/to/v-analyzer/bin/v-analyzer"
}
```

> **Note**
> Restart VS Code after changing the settings or PATH.

### Config

v-analyzer is configured using global or local config.
The global config is located in `~/.config/v-analyzer/config.toml`, changing it will affect all
projects.

A local config can be created with the `v-analyzer init` command at the root of the project.
Once created, it will be in `./.v-analyzer/config.toml`.
Each setting in the config has a detailed description.

Pay attention to the `custom_vroot` setting, if v-analyzer cannot find where V was installed, then
you will need to specify the path to it manually in this field.

## Updating

To update `v-analyzer` to the latest version, run:

```bash
v-analyzer up
```

You can also update to a nightly version:

```bash
v-analyzer up --nightly
```

> **Note**
> In the nightly version you will get the latest changes, but they may not be stable!

## VS Code extension

This repository also contains the source code for the VS Code extension in the
[`editors/code`](https://github.com/vlang/v-analyzer/tree/main/editors/code)
folder.
It is also available via the [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=VOSCA.vscode-v-analyzer).

## NVIM LSP / Mason

For Neovim users, v-analyzer is available via [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#v_analyzer).
It is part of the mason registry and can be installated with:
`:LspInstall v_analyzer` for nvim-lspconfig, or `:MasonInstall v_analyzer` for Mason.

## Authors

- `jsonrpc`, `lsp`, `tree_sitter_v` modules written initially by
  [VLS authors](https://github.com/vlang/vls) and after that in 2023 it was modified by the
  [VOSCA](https://github.com/vlang-association).

## Thanks

- [VLS](https://github.com/vlang/vls) authors for the initial Language Server implementation!
- [vscode-vlang](https://github.com/vlang/vscode-vlang) authors for the first VS Code extension!
- [rust-analyzer](https://github.com/rust-lang/rust-analyzer)
  and
  [gopls](https://github.com/golang/tools/tree/master/gopls)
  for the inspiration!
- [Tree-sitter](https://github.com/tree-sitter/tree-sitter) authors for the cool parsing library!

## License

This project is under the **MIT License**.
See the
[LICENSE](https://github.com/vlang/v-analyzer/blob/main/LICENSE)
file for the full license text.

[badge__vscode_ext]: https://img.shields.io/badge/VS_Code-extension-1da2e2?logo=visualstudiocode&logoWidth=11&logoColor=959da5&labelColor=333
[badge__build_ci]: https://img.shields.io/github/actions/workflow/status/vlang/v-analyzer/build_ci.yml?style=flat-rounded&branch=main&logo=github&&logoColor=959da5&labelColor=333&label=Build
[badge__tests_ci]: https://img.shields.io/github/actions/workflow/status/vlang/v-analyzer/analyzer_tests.yml?style=flat-rounded&branch=main&logo=github&&logoColor=959da5&labelColor=333&label=Analyzer
[badge__tree_sitter_ci]: https://img.shields.io/github/actions/workflow/status/vlang/v-analyzer/test_tree_sitter_v.yml?style=flat-rounded&branch=main&logo=github&&logoColor=959da5&labelColor=333&label=Tree-sitter
[badge__vscode_ext_ci]: https://img.shields.io/github/actions/workflow/status/vlang/v-analyzer/vscode_extension_tests.yml?style=flat-rounded&branch=main&logo=github&&logoColor=959da5&labelColor=333&label=VS%20Code%20Extension
