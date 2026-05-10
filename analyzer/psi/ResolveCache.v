@[translated]
module psi

import sync
import loglib

__global resolve_cache = ResolveCache{}

pub struct ResolveCache {
mut:
	mutex sync.RwMutex
	data  map[string]PsiElement
}

pub fn (t &ResolveCache) get(element PsiElement) ?PsiElement {
	t.mutex.@rlock()
	defer {
		t.mutex.runlock()
	}

	fingerprint := t.element_fingerprint(element)
	return t.data[fingerprint] or { return none }
}

pub fn (mut t ResolveCache) put(element PsiElement, result PsiElement) PsiElement {
	t.mutex.@lock()
	defer {
		t.mutex.unlock()
	}

	fingerprint := t.element_fingerprint(element)
	t.data[fingerprint] = result
	return result
}

pub fn (mut t ResolveCache) clear() {
	t.mutex.@lock()
	defer {
		t.mutex.unlock()
	}

	loglib.with_fields({
		'cache_size': t.data.len.str()
	}).log_one(.info, 'Clearing resolve cache')

	t.data = map[string]PsiElement{}
}

@[inline]
fn (_ &ResolveCache) element_fingerprint(element PsiElement) string {
	file := element.containing_file() or { return '' }
	range := element.text_range()
	return '${file.path}:${element.node().type_name}:${range.line}:${range.column}:${range.end_column}:${range.end_line}'
}
