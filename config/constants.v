module config

import os

// analyzer_name is the name of the analyzer.
pub const analyzer_name = 'v-analyzer'

// analyzer_config_name is the name of the analyzer's configuration
pub const analyzer_config_name = 'config.toml'

// analyzer_configs_path is the path to the directory containing the
// root configuration files for the analyzer.
pub const analyzer_configs_path = os.join_path(os.home_dir(), '.config', 'v-analyzer')

// analyzer_local_configs_folder_name is the name of the directory
// containing the local configuration files for the analyzer.
pub const analyzer_local_configs_folder_name = '.v-analyzer'

// analyzer_log_file_name is the name of the log file for the analyzer.
pub const analyzer_log_file_name = 'v-analyzer.log'

// analyzer_logs_path is the path to the directory containing the
// logs for the analyzer.
pub const analyzer_logs_path = os.join_path(analyzer_configs_path, 'logs')

// analyzer_global_config_path is the path to the global configuration
// file for the analyzer.
pub const analyzer_global_config_path = os.join_path(analyzer_configs_path, analyzer_config_name)

// analyzer_caches_path is the path to the directory containing the
// cache files for the analyzer.
pub const analyzer_caches_path = os.join_path(os.cache_dir(), 'v-analyzer')

// analyzer_stubs_path is the path to the directory containing the
// unpacked stub files for the analyzer.
pub const analyzer_stubs_path = os.join_path(analyzer_configs_path, 'metadata')

// analyzer_stubs_version_path is the path to the file containing the version of the stubs.
pub const analyzer_stubs_version_path = os.join_path(analyzer_stubs_path, 'version.txt')

pub const default = '# Specifies the path to the V installation directory with `v` executable.
# If not set, the plugin will try to find it on its own.
# Set it if you get errors like "Cannot find V standard library!".
#custom_vroot = "~/v"

# Specifies the path where to store the cache.
# By default, it is stored in the system\'s cache directory.
# You can set it to `./` to store the cache in the project\'s directory, this is useful
# if you want to debug the analyzer.
# Basically, you don\'t need to set it.
#custom_cache_dir = "./"

# Specifies whenever to enable semantic tokens or not.
# - `full` — enables all semantic tokens. In this mode analyzer resolves all symbols
#    in the file to provide the most accurate highlighting.
# - `syntax` — enables only syntax tokens, such tokens highlight structural elements
#    such as field names or import names.
#    The fastest option, which is always enabled when the file contains more than 1000 lines.
# - `none` — disables semantic tokens.
# By default, `full` for files with less than 1000 lines, `syntax` for files with more.
enable_semantic_tokens = "full"

# Specifies inlay hints to show.
[inlay_hints]
# Specifies whenever to enable inlay hints or not.
# By default, they are enabled.
enable = true

# Specifies whenever to show type hints for ranges or not.
# Example:
# ```
# 0 ≤ .. < 10
#   ^    ^
# ```
# or:
# ```
# a[0 ≤ .. < 10]
#     ^    ^
# ```
enable_range_hints = true

# Specifies whenever to show type hints for variables or not.
# Example:
# ```
# name : Foo := foo()
#      ^^^^^
# ```
enable_type_hints = true

# Specifies whenever to show hints for implicit err variables or not.
# Example:
# ```
# foo() or { err ->
#            ^^^^^^
# }
# ```
enable_implicit_err_hints = true

# Specifies whenever to show hints for function parameters in call or not.
# Example:
# ```
# fn foo(a int, b int) int {}
#
# foo(a: 1, b: 2)
#     ^^    ^^
enable_parameter_name_hints = true

# Specifies whenever to show type hints for constants or not.
# Example:
# ```
# const foo : int = 1
#           ^^^^^
# ```
enable_constant_type_hints = true

# Specifies whenever to show hints for enum field values or not.
# Example:
# ```
# enum Foo {
#   bar = 0
#       ^^^
#   baz = 1
#       ^^^
# }
# ```
enable_enum_field_value_hints = true

# Specifies code lenses to show.
[code_lens]
# Specifies whenever to enable code lenses or not.
# By default, they are enabled.
enable = true

# Specifies whenever to show code lenses for main function to run current directory or not.
# Example:
# ```
# ▶ Run
# fn main() {}
# ```
enable_run_lens = true

# Specifies whenever to show code lenses for interface inheritors or not.
# Example:
# ```
# 2 implementations
# interface Foo {}
# ```
enable_inheritors_lens = true

# Specifies whenever to show code lenses for structs implementing interfaces or not.
# Example:
# ```
# implemented 2 interfaces
# struct Boo {}
# ```
enable_super_interfaces_lens = true

# Specifies whenever to show code lenses for test functions to run test or whole file or not.
# Example:
# ```
# ▶ Run test | all file tests
# fn test_foo() {}
# ```
# Note: "all file tests" is shown only for the first test function in the file.
enable_run_tests_lens = true
'
