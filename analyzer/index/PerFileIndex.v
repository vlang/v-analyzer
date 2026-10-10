module index

import analyzer.psi

// PerFileIndex describes the cache of a group of files in the index.
pub struct PerFileIndex {
pub mut:
	data map[string]FileIndex
}

pub fn (p &PerFileIndex) get_sinks() []psi.StubIndexSink {
	mut res := []psi.StubIndexSink{cap: p.data.len}
	for _, cache in p.data {
		if !isnil(cache.sink) {
			res << *cache.sink
		}
	}
	return res
}

pub fn (mut p PerFileIndex) rename_file(old string, new string) ?FileIndex {
	if old == new {
		return none
	}
	if mut cache := p.data[old] {
		cache.stub_list.path = new
		p.data[new] = cache
		p.data.delete(old)
		return cache
	}

	return none
}

pub fn (mut p PerFileIndex) remove_file(path string) ?FileIndex {
	if mut cache := p.data[path] {
		p.data.delete(path)
		return cache
	}

	return none
}
