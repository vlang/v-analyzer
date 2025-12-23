module server

import lsp
import loglib
import os

pub fn (mut ls LanguageServer) did_change_watched_files(params lsp.DidChangeWatchedFilesParams) {
	changes := params.changes
	mut is_rename := false
	mut structure_changed := false

	// NOTE:
	// 1. Renaming a file returns two events: one "created" event for the
	//    same file with new name and one "deleted" event for the file with
	//    old name.
	// 2. Deleting a folder does not trigger a "deleted" event. Restoring
	//    the files of the folder however triggers the "created" event.
	// 3. Renaming a folder triggers the "created" event for each file
	//    but with no "deleted" event prior to it.
	for i, change in changes {
		change_uri := change.uri.normalize()

		filename := os.file_name(change_uri.path())
		if filename == 'v.mod' || filename == '.git' {
			structure_changed = true
		}

		match change.typ {
			.created {
				if next_change := changes[i + 1] {
					is_rename = next_change.typ == .deleted
				}

				if is_rename {
					prev_change := changes[i + 1] or { continue }
					prev_uri := prev_change.uri.normalize()
					if file_index := ls.indexing_mng.indexer.rename_file(prev_uri.path(),
						change_uri.path())
					{
						if isnil(file_index.sink) {
							continue
						}

						ls.indexing_mng.update_stub_indexes_from_sinks([*file_index.sink])

						loglib.with_fields({
							'old': prev_uri.path()
							'new': change_uri.path()
						}).info('Renamed file')
					}
				} else {
					if file_index := ls.indexing_mng.indexer.add_file(change_uri.path()) {
						if isnil(file_index.sink) {
							continue
						}

						ls.indexing_mng.update_stub_indexes_from_sinks([*file_index.sink])

						loglib.with_fields({
							'file': change_uri.path()
						}).info('Added file')
					}
				}
			}
			.deleted {
				if is_rename {
					continue
				}
				if file_index := ls.indexing_mng.indexer.remove_file(change_uri.path()) {
					if isnil(file_index.sink) {
						continue
					}

					ls.indexing_mng.update_stub_indexes_from_sinks([*file_index.sink])

					loglib.with_fields({
						'file': change_uri.path()
					}).info('Removed file')
				}
			}
			.changed {}
		}

		ls.client.log_message(change.str(), .info)
	}

	if structure_changed {
		loglib.info('Project structure changed, clearing project root cache')
		ls.project_resolver.clear()

		for uri, _ in ls.opened_files {
			ls.run_diagnostics_in_bg(uri)
		}
	}
}
