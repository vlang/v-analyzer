# v-analyser Changelog

## [0.0.4-beta.1] - 2024/01/09
Forth public release.

Note: this is still a beta version, do expect bugs, and report them in
our [issues tracker](https://github.com/vlang/v-analyzer/issues) .

### Syntax enhancements & bug fixes:
∙ Update comment rule (#5).
∙ Fix string interpolation.
∙ Fix comment string parse error (https://github.com/v-analyzer/v-analyzer/pull/85).
∙ Fix attribute shading (#2).
∙ Fix `parameters`.
∙ Fix the type descriptions in the primitives.v stub.
∙ Simplify `handle_jsonrpc` (https://github.com/v-analyzer/v-analyzer/pull/86).

### VSCode Extension:
∙ Show the full path to the found v-analyzer binary,
  when the VSCode extension runs its bootstrap, to make
  diagnosing problems easier.
∙ Update the vscode extension package to vscode-v-analyzer-0.0.4.vsix

### CI enhancements:
∙ Use `ubuntu-20.04` for building the executables, to be compatible with more Linux distros.
∙ Use `v build.vsh debug` for nightly releases, so the executables produce usable backtraces.
∙ Silence the nightly releases, simplify the .yml script that builds
  them (https://github.com/v-analyzer/v-analyzer/pull/83).

### Others:
∙ Update README.md to also include instructions for the mason.nvim Neovim
  package manager (https://github.com/v-analyzer/v-analyzer/pull/90).
∙ Fix notices and warnings with latest V.
∙ Exclude .git/* and `_test.v` files from indexing by the language server,
  see (https://github.com/v-analyzer/v-analyzer/pull/89).
∙ Use a git submodule for https://github.com/tree-sitter/tree-sitter.git, see
  (https://github.com/v-analyzer/v-analyzer/pull/81).
∙ Use gcc for building on windows (https://github.com/v-analyzer/v-analyzer/pull/87).
∙ Update build scripts (https://github.com/v-analyzer/v-analyzer/pull/84).
∙ Fix version comparison in install.vsh .
∙ Migrate from https://github.com/v-analyzer/v-analyzer/ to https://github.com/vlang/v-analyzer/ .

## [0.0.3-beta.1] - 2023/12/13
Third public release.

### Syntax enhancements & bug fixes:
∙ Fix support for multiline comments (https://github.com/v-analyzer/v-analyzer/pull/75)
∙ Fix interface ref type highlight (https://github.com/v-analyzer/v-analyzer/pull/76)
∙ Fix support for struct field attributes (https://github.com/v-analyzer/v-analyzer/pull/74)
∙ Fix interface embeds and interface fields (https://github.com/v-analyzer/v-analyzer/pull/78)
∙ Fix `assert cond, message` statements (https://github.com/v-analyzer/v-analyzer/pull/65)
∙ Support @[attribute], fix signature, fix interface highlights

### Language server enhancements:
∙ Enable exit commands, to prevent lingering v-analyzer processes after
an editor restart (https://github.com/v-analyzer/v-analyzer/pull/77)
∙ server: fix NO_RESULT_CALLBACK_FOUND in neovim (https://github.com/v-analyzer/v-analyzer/pull/59)
∙ Build the v-analyzer executable on linux as static in release mode, to
make it more robust and usable in more distros.

### Others:
∙ docs: add neovim install instructions (https://github.com/v-analyzer/v-analyzer/pull/63)
∙ CI improvements, to make releases easier, and to keep the code quality high.
∙ Update the vscode extension package to vscode-v-analyzer-0.0.3.vsix
∙ Make `v-analyzer --version` show the build commit as well.

Note: this is still a beta version, expect bugs and please report them in
our [issues tracker](https://github.com/vlang/v-analyzer/issues) .

## [0.0.2-beta.1] - 2023/11/21
Second public release. 

Small internal improvements to the documentation, ci, build scripts.

Fix compilation with latest V.

Update https://github.com/v-analyzer/v-tree-sitter from the latest
upstream version from https://github.com/tree-sitter/tree-sitter .

This is still a beta version, expect bugs and please report them in
our [issues tracker](https://github.com/vlang/v-analyzer/issues) .


## [0.0.1-beta.1] - 2023/07/03

First public release.

Please note that this is a beta version, so it may contain any bugs.
