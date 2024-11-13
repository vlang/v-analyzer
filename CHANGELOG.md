# v-analyser Changelog

## [0.0.5] - 2024/11/13
Fifth public release.

### New features and enhancements:
∙ analyzer: add module index paths and wrapper module path as code block (#102)
∙ analyzer: add `pub` access modifier to publicly used struct fields (#85)
∙ analyzer: create vtmp directory for check-updates/up commands (#125)
∙ analyzer: fix anonymous functions are self-invoking type mismatch (#48)
∙ analyzer: fix build for paths with spaces (#83)
∙ analyzer: Fix `code_description` (fixes zed-v) (#119)
∙ analyzer: fix doc_comment_extractor (#50)
∙ analyzer: fix vmodules_root check in setup_vpaths (#95)
∙ analyzer: fix work progress shown as 0% when finishing indexing (#84)
∙ analyzer: improve setup, extend client and log messages (#100)
∙ analyzer: merge creation of vtmp directory for check-updates/up commands (#126)
∙ analyzer: move const used to download install.vsh script (#127)
∙ analyzer: reduce nesting in setup_toolchain
∙ analyzer: rework path handling to simplify and reduce load (#86)
∙ analyzer: simplify, improve completion context detection
∙ analyzer: simplify, remove unnecessary abstraction
∙ analyzer: update deprecated
∙ analyzer: update deprecated unix time access (#99)
∙ analyzer: use latest install script when updating (#81)
∙ analyzer: support shebang syntax (#34)
∙ analyzer: add inline struct field comments (#52)
∙ analyzer: use build version aware caching (#57)
∙ analyzer: update parser.c to align with the current development state (#13), fixes highlighting for code in between 2 block comments
∙ build: follow a default directory structure for V projects (#25)
∙ build: update install.vsh to make repeated usage of path expand fn obsolete (#24)
∙ install: add debug and dev binaries install (#60)
∙ install: update the `git clone` options for install.vsh
∙ server: add `range_clause` highlight (#9)
∙ tree_sitter: correctly recognize shebang (#26)
∙ tree_sitter: support `for mut is` clause (#77)
∙ tree_sitter: support short lambda (#56)
∙ tree_sitter: detach shebang from comment (#32)

### Fixes to existing features:
∙ fix: building of IndexingRoot.v
∙ fix: fix behaviour of pascal_case_to_snake_case after V commit 5329a0a67
∙ fix: fix goto definition for field names. (#135)
∙ fix: fix hanging on vfmt-ing large files on windows (#130)
∙ fix: fix install.vsh
∙ fix: fix module index by making sure to index also src/ and modules/ folders too (#138)
∙ fix: fix raw string with `\` (#64)
∙ fix: fix wrong macos target in release CI (#139)
∙ fix: move tools/project-checker.v to its corresponding directory
∙ fix: remove obsolete v.mod file in metadata submod
∙ fix: resolve compiler complaints (#27)
∙ fix: restore `.v` extensions for metadata/stubs, add test (#74)
∙ fix: src/analyzer/index/IndexingRoot.v
∙ fix: tree-sitter bindings examples, extend workflow to run examples
∙ fix: update npm `generate` script
∙ fix: version regression after eae3f91, add test (#61)
∙ tree_sitter: fix issuse bug (#42)
∙ tree_sitter: fix parser error on unescaped dollar identifier in string literals, add test (#79)
∙ tree_sitter: fix parsing of nested comments, extend tests (#76)
∙ tree_sitter: fix qualified type (#8)
∙ tree_sitter: rewrite comment grammar, detach line- and block comments (#71)
∙ tree_sitter: add sum type to tree node (#87)

### Documentation:
∙ docs: update README.md with more detailed instructions about how to clone the project locally, fix `v check-md` warnings
∙ docs: fix for Neovim LSP/Mason (#122)
∙ docs: fix typo in readme
∙ docs: make submodule info in readme better visible and its commands easier to copy
∙ docs: refine readme before a potential structural update
∙ docs: update readme badges (#38)
∙ docs: update README.md mason install instructions (from https://github.com/v-analyzer/v-analyzer/pull/102)
∙ docs: update workflow path in tree-sitter badge

### Others:
∙ chore: fix typos (#44)
∙ chore: format all the files with the new fmt (#112)
∙ chore: format all the files with the new vfmt (#117)
∙ chore: format all the files with the new vfmt (#120)
∙ chore: format all the files with the new vfmt (#121)
∙ chore: run `v fmt -w install.vsh`
∙ chore: remove obsolete `.editorconfig` file in subdir, format
∙ chore: remove useless `compiler_flag` and copy `.exe` on windows (#108)
∙ chore: run the linter CI for changes made to just .vsh files too
∙ chore: updare editors/code dependencies (#33)
∙ chore: update deprecated `index_last` to `last_index` (#72)
∙ chore: update .gitattributes (#70)
∙ chore: update tree-sitter dependencies (#31)
∙ chore: use `.vv` extension for meta- and testdata files (#53)
∙ ci: add concurrency config (#67)
∙ ci: add linting and formatting automation to tree-sitter_v (#68)
∙ ci: add retry to release/build-vscode (#54)
∙ ci: add step to verify code formatting (#66)
∙ ci: add `.vsix` artifacts to release asset uploads (#47)
∙ ci: change `actions/upload-artifact@v3` to `actions/upload-artifact@v4` (#20)
∙ ci: change `vlang/setup-v@v1.3` to `vlang/setup-v@v1.4` (#19)
∙ ci: extend coverage in workflows
∙ ci: extend release workflow; automate assets uploads on tag creation (#39)
∙ ci: fix binary path in nightly ci (#36)
∙ ci: make sure that install_ci.yml is run for every change.
∙ ci: simplify, cover CI changes (#30)
∙ ci: use dedicated lint workflow to verify formatting (#97)
∙ refactor: decouple tree_sitter grammar and bindings (#37)
∙ refactor: simplify doc_comment_extractor, reduce load (#51)
∙ refactor: simplify grammar for `in/!in` and `is/!is`
∙ refactor: simplify path handling, remove unused utils (#40)
∙ refactor: store project metadata in metadata module (#59)
∙ refactor: update project structure (#69)
∙ tests: add test for the toolchain path setup (#96)
∙ tests: fix paths in bindings test, add test to workflow
∙ tests: fix analyzer test (#92)
∙ tests: update testdata (#45)
∙ tests: update tests to run with `v test` (#46)
∙ tree_sitter: add .prettierignore (#89)
∙ tree_sitter: improve clarity and quality of grammar (#78)
∙ tree_sitter: improve selector expression grammar
∙ tree_sitter: minimal cleanup, add optional `;` support between statements in {} blocks (#88)
∙ tree_sitter: Update dependencies (#18)
∙ tree_sitter: update tree-sitter-cli version to 0.22.2 (#41)


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
