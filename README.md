<img width="200px" src="https://github.com/vlang/v-analyzer/blob/2d5d12e4b82ce8d695576957145ff27a33a988c2/docs/cover-light.png#gh-light-mode-only">
<img width="200px" src="https://github.com/vlang/v-analyzer/blob/2d5d12e4b82ce8d695576957145ff27a33a988c2/docs/cover-dark.png#gh-dark-mode-only">

# v-analyzer

[![][badge__vscode_ext]](https://marketplace.visualstudio.com/items?itemName=VOSCA.vscode-v-analyzer)
[![][badge__build_ci]](https://github.com/vlang/v-analyzer/actions/workflows/build_ci.yml?query=branch%3Amain)
[![][badge__tests_ci]](https://github.com/vlang/v-analyzer/actions/workflows/analyzer_tests.yml?query=branch%3Amain)
[![][badge__tree_sitter_ci]](https://github.com/vlang/v-analyzer/actions/workflows/tree_sitter_v.yml?query=branch%3Amain)
[![][badge__vscode_ext_ci]](https://github.com/vlang/v-analyzer/actions/workflows/vscode_extension_tests.yml?query=branch%3Amain)

Bring IDE features for the V programming language to VS Code, Vim, and other editors.

The features provided by v-analyzer include:

- code completion/IntelliSense
- go to definition, type definition
- find all references, document symbol, symbol renaming
- types and documentation on hover
- inlay hints for types and some construction like `or` block
- semantic syntax highlighting
- formatting
- signature help

## Installation

### Linux, macOS, Windows
Note: the following command will download `install.vsh` to the current directory, then 
run it, and then *delete it*. If there is a pre-existing file with this name, make sure it
is safe, when it is overwritten/deleted, or change the current directory (the script itself
can be run from anywhere).

```sh 
v download -RD https://raw.githubusercontent.com/vlang/v-analyzer/main/install.vsh
```

Note: if you get messages about `response does not start with HTTP/`, try going to the
main V repository, then do `./v -d use_openssl cmd/tools/vdownload.v` .
After that, retry the same command:
```sh 
v download -RD https://raw.githubusercontent.com/vlang/v-analyzer/main/install.vsh
```

## Pre-built binaries

You can download pre-built binaries from the [release page](https://github.com/vlang/v-analyzer/releases).
Currently, we provide binaries for Linux (x64), macOS (x64 and ARM), and Windows (x64).

## Building from source

> [!NOTE]
> This repository uses Git submodules.
> In practice, this means that you either have to:
>
> ```sh
> git clone --filter=blob:none --recursive --shallow-submodules https://github.com/vlang/v-analyzer
> ```
>
> ... or, if you used just `git clone https://github.com/vlang/v-analyzer`, you can execute below
> inside your local `v-analyzer` clone:
>
> ```sh
> git submodule init && git submodule update
> ```
>
> If you do not do either, the symptom is that when you try to build v-analyzer, you will get a
> C compiler message, about `lib.c not found`

> [!TIP]
> On Windows, use GCC for building, as TCC can run into some issues.

Update V to the latest version:

```bash
v up
```

You can build a debug or release version of the binary.
The debug version will be slower, but faster to compile.

```bash
v build.vsh debug
```

```bash
v build.vsh release
```

The compiled binary will be located in the `bin/` folder.

## Setup

Add the `bin/` folder to your `$PATH` environment variable to make the `v-analyzer` command easily
accessible.

You can also specify the path to the binary in your VS Code settings:

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

The VS Code extension is available via the [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=VOSCA.vscode-v-analyzer).
The source code for extension is contained in the [`editors/code`](https://github.com/vlang/v-analyzer/tree/main/editors/code) folder of this repository.

## NVIM LSP / Mason

For Neovim users, v-analyzer is available via [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#v_analyzer) plugin.
It is part of the [mason registry](https://mason-registry.dev/registry/list#v-analyzer) and could be installed with both Neovim plugins:
- [mason.nvim](https://github.com/williamboman/mason.nvim) with `:MasonInstall v-analyzer` command
- [mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim) with `:LspInstall` command

## Authors

- `jsonrpc`, `lsp`, `tree_sitter_v` modules written initially by
  [VLS authors](https://github.com/vlang/vls) and after that in 2023 it was modified by the
  [VOSCA](https://github.com/vlang-association).

## Thanks

- [VLS](https://github.com/vlang/vls) authors for the initial Language Server implementation!
- [vscode-vlang](https://github.com/vlang/vscode-vlang) authors for the first VS Code extension!
- [rust-analyzer](https://github.com/rust-lang/rust-analyzer) and [gopls](https://github.com/golang/tools/tree/master/gopls) for the inspiration!
- [Tree-sitter](https://github.com/tree-sitter/tree-sitter) authors for the cool parsing library!

## License

This project is under the **MIT License**.
The full license text can be found in the [LICENSE](https://github.com/vlang/v-analyzer/blob/main/LICENSE) file.

[badge__vscode_ext]: https://img.shields.io/badge/VS_Code-extension-1da2e2?logo=visualstudiocode&logoWidth=11&logoColor=959da5&labelColor=333
[badge__build_ci]: https://img.shields.io/github/actions/workflow/status/vlang/v-analyzer/build_ci.yml?style=flat-rounded&branch=main&logo=github&&logoColor=959da5&labelColor=333&label=Build
[badge__tests_ci]: https://img.shields.io/github/actions/workflow/status/vlang/v-analyzer/analyzer_tests.yml?style=flat-rounded&branch=main&logo=github&&logoColor=959da5&labelColor=333&label=Analyzer
[badge__tree_sitter_ci]: https://img.shields.io/github/actions/workflow/status/vlang/v-analyzer/tree_sitter_v.yml?style=flat-rounded&branch=main&logo=github&&logoColor=959da5&labelColor=333&label=Tree-sitter
[badge__vscode_ext_ci]: https://img.shields.io/github/actions/workflow/status/vlang/v-analyzer/vscode_extension_tests.yml?style=flat-rounded&branch=main&logo=github&&logoColor=959da5&labelColor=333&label=VS%20Code%20Extension
