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

## Usage

- [Installation](https://github.com/vlang/v-analyzer/wiki/Installation)
  - [Linux and macOS](https://github.com/vlang/v-analyzer/wiki/Installation#linux-and-macos)
  - [Windows](https://github.com/vlang/v-analyzer/wiki/Installation#windows)
- [Updating](https://github.com/vlang/v-analyzer/wiki/Installation#updating)
- [Editor Setup](https://github.com/vlang/v-analyzer/wiki/Installation#editor-setup)
  - [VS Code](https://github.com/v-analyzer/v-analyzer/wiki/editor-plugins#vscode)
  - [Neovim](https://github.com/vlang/v-analyzer/wiki/Installation#neovim)
- [Configuration](https://github.com/vlang/v-analyzer/wiki/Config)
- [Building and Development](https://github.com/vlang/v-analyzer/wiki/Development)

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
