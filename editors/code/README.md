# v-analyzer support for Visual Studio Code

[![VSCode Extension](https://img.shields.io/badge/VS_Code-extension-25829e?logo=visualstudiocode&logoWidth=10)](https://marketplace.visualstudio.com/items?itemName=VOSCA.vscode-v-analyzer)
[![VS Code extension tests](https://github.com/vlang/v-analyzer/actions/workflows/vscode_extension_tests.yml/badge.svg)](https://github.com/vlang/v-analyzer/actions/workflows/vscode_extension_tests.yml)

Provides
[V programming language](https://vlang.io)
and
[`v-analyzer`](https://github.com/vlang/v-analyzer)
support for Visual Studio Code.
It is recommended over and replaces
[V extension](https://marketplace.visualstudio.com/items?itemName=vlanguage.vscode-vlang).

For most of its functionality, the extension uses
[`v-analyzer`](https://github.com/vlang/v-analyzer),
which we will refer to as the server to avoid confusion.

## Features

- syntax highlighting
- code completion
- go to definition, type definition
- find all references, document symbol, symbol renaming
- types and documentation on hover
- inlay hints for types and some construction like `or` block
- semantic syntax highlighting
- formatting
- signature help

## Getting started

Welcome! 👋🏻

Let's get started setting up **v-analyzer** in VS Code!

1. First of all, make sure you have the latest version of V installed.
   If you are unsure, run `v up` to update.

2. Now let's install VS Code **v-analyzer** extension:

    1. Open the command palette with `Ctrl+Shift+P` or `Cmd+Shift+P`
    2. Select `Install Extensions` and choose `v-analyzer`.

   You can also install the extension manually:

    1. Select `Install from VSIX...`
    2. Choose pre-built VSIX file from this folder or build it yourself

   After installation, restart VS Code.

3. Open any project that contains files with `.v` extension.
   The extension should automatically activate.
   Upon activation, the extension will try to find `v-analyzer` server, which
   is the heart of the extension and provides all the smart features.

4. Since `v-analyzer` server is not installed
   (unless you installed it in advance and added it to PATH, in which case you
   can skip this step), the extension will prompt you to install it.
   Click `Install` and wait for the installation to complete.

5. After installing `v-analyzer` server, the extension will prompt you to
   restart the `v-analyzer` server.
   Click `Yes` and wait for the restart to complete.

6. When `v-analyzer` server is successfully restarted,
   it will start to analyze your project as well as the V standard library.

7. Note that if `v-analyzer` server cannot find where the V standard library
   is stored, an error will be shown.

   In this case, follow the instructions in the error and specify the path to
   the V source code folder in the `custom_vroot` field.

   > **Note**
   > You need to specify the folder where all the V sources are stored
   > (e.g. `C:\v\` or `/home/user/v/` and not the folder with the standard library
   > (e.g. `C:\v\vlib` or `/home/user/v/vlib`)!
   > After making changes, restart `v-analyzer` using the `v-analyzer: Restart server`
   > command in the command palette.

8. If the server was able to find all the necessary things, then after a while the
   indexing will end, and you will be able to use all the features of `v-analyzer`.

   > **Note**
   > Indexing can take up to 30 seconds on weak machines, but this is only
   > done on the first run; then the indexes will be loaded from the cache.

You are ready to code in V! 🎉

## Manual Setup

You can install ``v-analyzer`` server manually:
Clone the
[`v-analyzer`](https://github.com/vlang/v-analyzer)
repository, build it and specify the path to the compiled binary.

```json
{
    "v-analyzer.serverPath": "path/to/v-analyzer"
}
```

## Auto save

`v-analyzer` uses `v` compiler to analyze code.
It calls it every time a file is saved, so you can set up auto-save to get real-time
feedback.

```json
{
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 300
}
```

## Semantic tokens

With highlighting based on TextMate grammar, v-analyzer provides semantic
highlighting, which allows you to highlight fields, variables, parameters and other
elements as different entities.

To enable semantic highlighting, make sure the `editor.semanticHighlighting.enabled`
setting is set to `true` in the VS Code settings.

In the settings, you can also specify colors for each entity type:

```json
{
    "editor.semanticTokenColorCustomizations": {
        "[Theme Name]": {
            "rules": {
                "namespace": "#AFBF7E",
                "parameter": "#B189F5",
                "decorator": "#DEBC7E",
                "typeParameter": "#B189F5",
                "enumMember": "#72CFD6",
                "*.global": "#A9B7C6",
                "function": "#FFC66D",
                "*.mutable": {
                    "underline": true
                }
            }
        }
    }
}
```

See
[all available entity types](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#semanticTokenTypes)
in the LSP specification.

## Building from source

```bash
npm install
npm run package
```

## License

This project is under the **MIT License**.
See the
[LICENSE](https://github.com/vlang/v-analyzer/blob/main/editors/code/LICENSE)
file for the full license text.
