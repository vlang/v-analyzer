module psi

@[heap]
pub struct StubIndexSink {
pub mut:
	stub_id          StubId
	stub_list        &StubList = unsafe { nil } // List of stubs in the current file for which the index is being built.
	imported_modules []string
	kind             StubIndexLocationKind
	data             map[int]map[string][]StubId
}

const non_fqn_keys = [StubIndexKey.global_variables, .methods_fingerprint, .fields_fingerprint,
	.interface_methods_fingerprint, .interface_fields_fingerprint, .methods, .static_methods,
	.attributes, .modules_fingerprint]

fn (mut s StubIndexSink) occurrence(key StubIndexKey, value string) {
	module_fqn := s.module_fqn()
	resulting_value := if module_fqn != '' && key !in psi.non_fqn_keys {
		'${module_fqn}.${value}'
	} else {
		value
	}

	s.data[int(key)][resulting_value] << s.stub_id
}

@[inline]
pub fn (s StubIndexSink) module_fqn() string {
	if s.stub_list == unsafe { nil } {
		return ''
	}
	return s.stub_list.module_fqn
}
