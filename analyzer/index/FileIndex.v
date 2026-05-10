module index

import analyzer.psi

// FileIndex describes the cache of a single file.
// By splitting the cache into files, we can index files in parallel
// without the need for synchronization.
@[heap]
pub struct FileIndex {
pub mut:
	kind IndexingRootKind // root where the file is located
	// file_last_modified stores the time the file was last modified
	//
	// Thanks to it, while checking the cache, we can understand whether the
	// file has been changed or not.
	// If the file has been modified, then we reindex the file.
	file_last_modified i64
	// stub_list is a list of all stubs in the file.
	// Storing stubs as a table makes it easy and compact to save them to disk and load them back.
	stub_list &psi.StubList = unsafe { nil }
	// sink describes the indexed stubs of the current file.
	// So, for example, by the '.functions' key, you can get the stubs of all functions defined inside the current file.
	// See also 'StubIndexKey'.
	sink &psi.StubIndexSink = unsafe { nil }
}

pub fn (f &FileIndex) path() string {
	if f.stub_list == unsafe { nil } {
		return ''
	}
	return f.stub_list.path
}
