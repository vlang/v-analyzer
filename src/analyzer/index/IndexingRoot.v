module index

import time
import os
import sync
import runtime
import math
import loglib
import lsp
import crypto.md5
import analyzer.psi
import analyzer.parser

// BuiltIndexStatus describes the status of the built index.
pub enum BuiltIndexStatus {
	from_cache   // index was loaded from cache
	from_scratch // index was built from scratch
}

// IndexingRootKind describes the type of root that is being indexed.
// Same as `StubIndexKind`.
pub enum IndexingRootKind as u8 {
	standard_library
	modules
	stubs
	workspace
}

pub fn (k IndexingRootKind) readable_name() string {
	return match k {
		.standard_library { 'Standard Library' }
		.modules { 'Modules' }
		.stubs { 'Stubs' }
		.workspace { 'Workspace' }
	}
}

// IndexingRoot encapsulates the logic of indexing/reindexing a particular root of the file system.
//
// Separation into separate roots is necessary in order to process the standard library and user code separately.
@[noinit]
pub struct IndexingRoot {
pub:
	root string           // root that is indexed
	kind IndexingRootKind // type of root that is indexed
pub mut:
	cache_dir  string    // path to the directory where the index is stored
	updated_at time.Time // when the index was last updated
	index      Index     // index itself
	cache_file string    // path to the file where the index is stored
	need_save  bool      // whether the index needs to be saved
	no_save    bool      // for tests
}

// new_indexing_root creates a new indexing root with the given root and kind.
pub fn new_indexing_root(root string, kind IndexingRootKind, cache_dir string) &IndexingRoot {
	cache_file := 'v_analyzer_index_${md5.hexhash(root)}'
	return &IndexingRoot{
		root:       root
		kind:       kind
		cache_dir:  cache_dir
		cache_file: cache_file
	}
}

fn (mut i IndexingRoot) cache_file() string {
	return os.join_path(i.cache_dir, i.cache_file)
}

pub fn (mut i IndexingRoot) load_index() ! {
	now := time.now()
	if !os.exists(i.cache_file()) {
		loglib.with_fields({
			'root': i.root
		}).info('Index not found, start indexing')
		return IndexNotFoundError{}
	}

	data := os.read_bytes(i.cache_file()) or {
		loglib.with_fields({
			'file':  i.cache_file()
			'error': err.str()
		}).error('Failed to read index')
		return IndexNotFoundError{}
	}
	i.index.decode(data) or {
		if err is IndexVersionMismatchError {
			loglib.info('Index version mismatch')
		} else {
			loglib.with_fields({
				'file':  i.cache_file()
				'error': err.str()
			}).error('Error load index')
		}
		return NeedReindexedError{}
	}
	loglib.info('Loaded index in ${time.since(now)}')
}

pub fn (mut i IndexingRoot) save_index() ! {
	if !i.need_save || i.no_save {
		return
	}
	i.need_save = false

	data := i.index.encode()
	os.write_file_array(i.cache_file(), data) or {
		loglib.with_fields({
			'file':  i.cache_file()
			'error': err.str()
		}).error('Failed to write analyzer index file')
		return err
	}
}

// need_index returns true if the file needs to be indexed.
//
// We deliberately do not index some of test files to speed up the indexing and searching process.
fn (mut _ IndexingRoot) need_index(path string) bool {
	if path.ends_with('.vsh') {
		return true
	}

	if !path.ends_with('.v') {
		return false
	}

	return !path.contains('/tests/') && !path.contains('/slow_tests/')
		&& !path.contains('/.vmodules/cache/')
		&& !path.contains('/builtin/wasm/') // TODO: index this folder too
		&& !path.contains('/builtin/js/') // TODO: index this folder too
		&& !path.contains('/builtin/linux_bare/') // TODO: index this folder too
		&& !path.ends_with('.js.v') && !path.contains('/.git/') && !path.ends_with('_test.v')
}

pub fn (mut i IndexingRoot) index() BuiltIndexStatus {
	now := time.now()

	loglib.with_fields({
		'root': i.root
	}).info('Indexing root')

	if _ := i.load_index() {
		loglib.with_duration(time.since(now)).info('Index loaded from cache')
		return .from_cache
	}

	file_chan := chan string{cap: 1000}
	cache_chan := chan FileIndex{cap: 1000}

	spawn fn [mut i, file_chan] () {
		path := i.root
		os.walk(path, fn [mut i, file_chan] (path string) {
			if i.need_index(path) {
				file_chan <- path
			}
		})

		file_chan.close()
	}()

	spawn i.spawn_indexing_workers(cache_chan, file_chan)

	mut caches := []FileIndex{cap: 100}
	for {
		cache := <-cache_chan or { break }
		caches << cache
	}

	for cache in caches {
		i.index.per_file.data[cache.path()] = cache
	}

	i.updated_at = time.now()
	i.need_save = true

	loglib.with_duration(time.since(now)).info('Indexing finished')
	return .from_scratch
}

pub fn (mut i IndexingRoot) index_file(path string, content string) !FileIndex {
	last_modified := os.file_last_mod_unix(path)
	res := parser.parse_code(content)
	psi_file := psi.new_psi_file(path, res.tree, content)
	module_fqn := psi.module_qualified_name(psi_file, i.root)

	mut cache := FileIndex{
		kind:               i.kind
		file_last_modified: last_modified
		sink:               &psi.StubIndexSink{
			kind:      unsafe { psi.StubIndexLocationKind(u8(i.kind)) }
			stub_list: unsafe { nil }
		}
		stub_list:          unsafe { nil }
	}
	stub_tree := build_stub_tree(psi_file, i.root)

	stub_type := psi.StubbedElementType{}
	mut stub_list := stub_tree.root.stub_list
	stub_list.module_fqn = module_fqn
	stub_list.path = path

	cache.sink.imported_modules = stub_tree.get_imported_modules()

	stubs := stub_list.index_map.values()
	for stub in stubs {
		cache.sink.stub_id = stub.id
		cache.sink.stub_list = stub.stub_list
		stub_type.index_stub(stub, mut cache.sink)
	}
	cache.stub_list = stub_list

	unsafe { res.tree.free() }
	return cache
}

pub fn (mut i IndexingRoot) spawn_indexing_workers(cache_chan chan FileIndex, file_chan chan string) {
	mut wg := sync.new_waitgroup()
	cpus := runtime.nr_cpus()
	workers := math.max(cpus - 4, 1)
	wg.add(workers)
	for j := 0; j < workers; j++ {
		spawn fn [file_chan, mut wg, mut i, cache_chan] () {
			for {
				filepath := <-file_chan or { break }
				content := os.read_file(filepath) or {
					loglib.with_fields({
						'uri':   lsp.document_uri_from_path(filepath).str()
						'error': err.str()
					}).error('Error reading file for index')
					continue
				}
				cache_chan <- i.index_file(filepath, content) or {
					loglib.with_fields({
						'uri':   lsp.document_uri_from_path(filepath).str()
						'error': err.str()
					}).error('Error indexing file')
					continue
				}
			}

			wg.done()
		}()
	}

	wg.wait()
	cache_chan.close()
}

// ensure_indexed checks the index for freshness and re-indexes files if they have changed since the last indexing.
pub fn (mut i IndexingRoot) ensure_indexed() {
	now := time.now()

	loglib.with_fields({
		'root': i.root
	}).info('Ensuring indexed root')

	reindex_files_chan := chan string{cap: 1000}
	cache_chan := chan FileIndex{cap: 1000}

	spawn fn [reindex_files_chan, mut i] () {
		for filepath, datum in i.index.per_file.data {
			last_modified := os.file_last_mod_unix(filepath)
			if last_modified > datum.file_last_modified {
				loglib.with_fields({
					'uri': lsp.document_uri_from_path(filepath).str()
				}).info('File was modified, reindexing')
				i.index.per_file.data.delete(filepath)
				reindex_files_chan <- filepath
			}
		}

		reindex_files_chan.close()
	}()

	spawn i.spawn_indexing_workers(cache_chan, reindex_files_chan)

	mut caches := []FileIndex{cap: 100}
	for {
		cache := <-cache_chan or { break }
		caches << cache
	}

	for cache in caches {
		i.index.per_file.data[cache.path()] = cache
	}

	if caches.len > 0 {
		i.index.updated_at = time.now()
		i.need_save = true
	}

	loglib.with_duration(time.since(now)).info('Reindexing finished')
}

pub fn (mut i IndexingRoot) mark_as_dirty(filepath string, new_content string) ! {
	if filepath !in i.index.per_file.data {
		// file does not belong to this index
		return
	}

	loglib.with_fields({
		'uri': lsp.document_uri_from_path(filepath).str()
	}).info('Marking document as dirty')
	i.index.per_file.data.delete(filepath)
	res := i.index_file(filepath, new_content) or {
		return error('Error indexing dirty ${filepath}: ${err}')
	}
	i.index.per_file.data[filepath] = res
	i.index.updated_at = time.now()
	i.need_save = true
	i.save_index() or { return err }

	loglib.with_fields({
		'uri': lsp.document_uri_from_path(filepath).str()
	}).info('Finished reindexing document')
}

pub fn (mut i IndexingRoot) add_file(filepath string, content string) !FileIndex {
	loglib.with_fields({
		'uri': lsp.document_uri_from_path(filepath).str()
	}).info('Adding new document')

	res := i.index_file(filepath, content) or {
		return error('Error indexing added ${filepath}: ${err}')
	}
	i.index.per_file.data[filepath] = res
	i.index.updated_at = time.now()
	i.need_save = true
	i.save_index() or { return err }

	loglib.with_fields({
		'uri': lsp.document_uri_from_path(filepath).str()
	}).info('Finished indexing added document')

	if isnil(res.sink) {
		return error('Sink of added file is nil')
	}

	return res
}

pub fn (mut i IndexingRoot) rename_file(old string, new string) !FileIndex {
	cache := i.index.per_file.rename_file(old, new) or {
		return error('cannot find file index after rename, most likely rename was failed')
	}
	i.need_save = true
	i.save_index() or { return err }
	if isnil(cache.sink) {
		return error('Sink of renamed file is nil')
	}
	return cache
}

pub fn (mut i IndexingRoot) remove_file(path string) !FileIndex {
	cache := i.index.per_file.remove_file(path) or {
		return error('cannot find file index after remove, most likely remove was failed')
	}
	i.need_save = true
	i.save_index() or { return err }
	if isnil(cache.sink) {
		return error('Sink of removed file is nil')
	}
	return cache
}

pub fn (i &IndexingRoot) contains(path string) bool {
	return path.starts_with(i.root)
}
