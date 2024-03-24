module metadata

import os
import v.vmod
import v.embed_file

pub const manifest = vmod.decode(@VMOD_FILE) or { panic(err) }
pub const build_datetime = $env('BUILD_DATETIME')
pub const build_commit = $env('BUILD_COMMIT')
pub const full_version = manifest.version + '.' + build_commit

struct EmbedFS {
pub mut:
	files []embed_file.EmbedFileData
}

pub fn (e &EmbedFS) unpack_to(path string) ! {
	for file in e.files {
		new_path := os.norm_path(os.join_path(path, file.path))
		dir := os.dir(new_path)
		if !os.exists(dir) {
			os.mkdir_all(dir) or { return error('failed to create directory ${dir}') }
		}
		os.write_file(new_path, file.to_string())!
	}
}

pub fn embed_fs() EmbedFS {
	mut files := []embed_file.EmbedFileData{}
	files << $embed_file('stubs/arrays.vv', .zlib)
	files << $embed_file('stubs/primitives.vv', .zlib)
	files << $embed_file('stubs/vweb.vv', .zlib)
	files << $embed_file('stubs/compile_time_constants.vv', .zlib)
	files << $embed_file('stubs/compile_time_reflection.vv', .zlib)
	files << $embed_file('stubs/builtin_compile_time.vv', .zlib)
	files << $embed_file('stubs/channels.vv', .zlib)
	files << $embed_file('stubs/README.md', .zlib)
	files << $embed_file('stubs/attributes/Deprecated.v', .zlib)
	files << $embed_file('stubs/attributes/Table.v', .zlib)
	files << $embed_file('stubs/attributes/Attribute.v', .zlib)
	files << $embed_file('stubs/attributes/DeprecatedAfter.v', .zlib)
	files << $embed_file('stubs/attributes/Unsafe.v', .zlib)
	files << $embed_file('stubs/attributes/Flag.v', .zlib)
	files << $embed_file('stubs/attributes/Noreturn.v', .zlib)
	files << $embed_file('stubs/attributes/Manualfree.v', .zlib)
	files << $embed_file('stubs/implicit.v', .zlib)
	files << $embed_file('stubs/compile_time.vv', .zlib)
	files << $embed_file('stubs/c_decl.vv', .zlib)
	files << $embed_file('stubs/errors.vv', .zlib)
	files << $embed_file('stubs/threads.vv', .zlib)
	files << $embed_file('v.mod', .zlib)

	return EmbedFS{
		files: files
	}
}
