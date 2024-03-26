module config

import toml

pub enum SemanticTokensMode {
	full
	syntax
	none_
}

pub struct InlayHintsConfig {
pub mut:
	enable                        bool = true
	enable_range_hints            bool = true
	enable_type_hints             bool = true
	enable_implicit_err_hints     bool = true
	enable_parameter_name_hints   bool = true
	enable_constant_type_hints    bool = true
	enable_enum_field_value_hints bool = true
}

pub struct CodeLensConfig {
pub mut:
	enable                       bool = true
	enable_run_lens              bool = true
	enable_inheritors_lens       bool = true
	enable_super_interfaces_lens bool = true
	enable_run_tests_lens        bool = true
}

pub struct EditorConfig {
pub:
	root string
	path string
pub mut:
	custom_vroot           string
	custom_cache_dir       string
	inlay_hints            InlayHintsConfig
	enable_semantic_tokens SemanticTokensMode = SemanticTokensMode.full
	code_lens              CodeLensConfig
}

pub fn from_toml(root string, path string, content string) !EditorConfig {
	mut econfig := EditorConfig{
		root: root
		path: path
	}

	res := toml.parse_text(content)!

	custom_vroot_value := res.value('custom_vroot')
	if custom_vroot_value is string {
		econfig.custom_vroot = custom_vroot_value
	}

	custom_cache_dir := res.value('custom_cache_dir')
	if custom_cache_dir is string {
		econfig.custom_cache_dir = custom_cache_dir
	}

	enable_semantic_tokens := res.value('enable_semantic_tokens')
	if enable_semantic_tokens is string {
		econfig.enable_semantic_tokens = match enable_semantic_tokens {
			'full' { SemanticTokensMode.full }
			'syntax' { SemanticTokensMode.syntax }
			'none' { SemanticTokensMode.none_ }
			else { SemanticTokensMode.full }
		}
	}

	inlay_hints_table := res.value('inlay_hints')
	enable_value := inlay_hints_table.value('enable')
	econfig.inlay_hints.enable = if enable_value is toml.Null {
		true // default to true
	} else {
		enable_value.bool()
	}

	enable_range_hints_value := inlay_hints_table.value('enable_range_hints')
	econfig.inlay_hints.enable_range_hints = if enable_range_hints_value is toml.Null {
		true // default to true
	} else {
		enable_range_hints_value.bool()
	}

	enable_type_hints_value := inlay_hints_table.value('enable_type_hints')
	econfig.inlay_hints.enable_type_hints = if enable_type_hints_value is toml.Null {
		true // default to true
	} else {
		enable_type_hints_value.bool()
	}

	enable_implicit_err_hints := inlay_hints_table.value('enable_implicit_err_hints')
	econfig.inlay_hints.enable_implicit_err_hints = if enable_implicit_err_hints is toml.Null {
		true // default to true
	} else {
		enable_implicit_err_hints.bool()
	}

	enable_parameter_name_hints := inlay_hints_table.value('enable_parameter_name_hints')
	econfig.inlay_hints.enable_parameter_name_hints = if enable_parameter_name_hints is toml.Null {
		true // default to true
	} else {
		enable_parameter_name_hints.bool()
	}

	enable_constant_type_hints := inlay_hints_table.value('enable_constant_type_hints')
	econfig.inlay_hints.enable_constant_type_hints = if enable_constant_type_hints is toml.Null {
		true // default to true
	} else {
		enable_constant_type_hints.bool()
	}

	enable_enum_field_value_hints := inlay_hints_table.value('enable_enum_field_value_hints')
	econfig.inlay_hints.enable_enum_field_value_hints = if enable_enum_field_value_hints is toml.Null {
		true // default to true
	} else {
		enable_enum_field_value_hints.bool()
	}

	code_lens_table := res.value('code_lens')
	enable_lens_value := code_lens_table.value('enable')
	econfig.code_lens.enable = if enable_lens_value is toml.Null {
		true // default to true
	} else {
		enable_lens_value.bool()
	}

	enable_run_lens := code_lens_table.value('enable_run_lens')
	econfig.code_lens.enable_run_lens = if enable_run_lens is toml.Null {
		true // default to true
	} else {
		enable_run_lens.bool()
	}

	enable_inheritors_lens := code_lens_table.value('enable_inheritors_lens')
	econfig.code_lens.enable_inheritors_lens = if enable_inheritors_lens is toml.Null {
		true // default to true
	} else {
		enable_inheritors_lens.bool()
	}

	enable_super_interfaces_lens := code_lens_table.value('enable_super_interfaces_lens')
	econfig.code_lens.enable_super_interfaces_lens = if enable_super_interfaces_lens is toml.Null {
		true // default to true
	} else {
		enable_super_interfaces_lens.bool()
	}

	enable_run_tests_lens := code_lens_table.value('enable_run_tests_lens')
	econfig.code_lens.enable_run_tests_lens = if enable_run_tests_lens is toml.Null {
		true // default to true
	} else {
		enable_run_tests_lens.bool()
	}

	return econfig
}

pub fn (e &EditorConfig) path() string {
	if e.path.starts_with(e.root) {
		return e.path[e.root.len + 1..]
	}

	return e.path
}

pub fn (e &EditorConfig) is_local() bool {
	return e.path.starts_with(e.root)
}
