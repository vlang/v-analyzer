@[translated]
module psi

import analyzer.psi.types
import sync
import loglib

__global type_cache = TypeCache{}

pub struct TypeCache {
mut:
	mutex sync.RwMutex
	data  map[string]types.Type
}

pub fn (t &TypeCache) get(element PsiElement) ?types.Type {
	t.mutex.@rlock()
	defer {
		t.mutex.runlock()
	}

	fingerprint := t.element_fingerprint(element)
	return t.data[fingerprint] or { return none }
}

pub fn (mut t TypeCache) put(element PsiElement, typ types.Type) types.Type {
	t.mutex.@lock()
	defer {
		t.mutex.unlock()
	}

	fingerprint := t.element_fingerprint(element)
	t.data[fingerprint] = typ
	return typ
}

pub fn (mut t TypeCache) clear() {
	t.mutex.@lock()
	defer {
		t.mutex.unlock()
	}

	loglib.with_fields({
		'cache_size': t.data.len.str()
	}).log_one(.info, 'Clearing type cache')

	t.data = map[string]types.Type{}
}

@[inline]
fn (_ &TypeCache) element_fingerprint(element PsiElement) string {
	file := element.containing_file() or { return '' }
	range := element.text_range()
	return '${file.path}:${element.node().type_name}:${range.line}:${range.column}:${range.end_column}:${range.end_line}'
}
