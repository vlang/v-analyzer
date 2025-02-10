#!/usr/bin/env -S v

// This script is used to build the v-analyzer binary.
// Usage: `v build.vsh [debug|dev|release]`
// By default, doing just `v build.vsh` will use debug mode.
import os
import cli
import term
import time
import src.metadata

const vexe = @VEXE
const bin_path = './bin/v-analyzer' + $if windows { '.exe' } $else { '' }
const build_commit = os.execute('git rev-parse --short HEAD').output.trim_space()
const build_time = time.now()
const build_datetime = build_time.format_ss()
const gcheck = term.green('✓')

enum ReleaseMode {
	release
	debug
	dev
}

fn eline(msg string) {
	eprintln('${term.red('[ERROR]')} ${msg}')
}

fn (m ReleaseMode) compile_cmd() string {
	base_build_cmd := '${os.quoted_path(@VEXE)} ${os.quoted_path(@VMODROOT)} -o ${quoted_path(bin_path)} -no-parallel'
	cc := if v := os.getenv_opt('CC') {
		'-cc ${v}'
	} else {
		$if windows {
			// TCC cannot build tree-sitter on Windows.
			'-cc gcc'
		} $else {
			// Let `-prod` toggle the appropriate production compiler.
			''
		}
	}
	cflags := $if cross_compile_macos_arm64 ? {
		'-cflags "-target arm64-apple-darwin"'
	} $else $if cross_compile_macos_x86_64 ? {
		'-cflags "-target x86_64-apple-darwin"'
	} $else $if linux {
		if m == .release { '-cflags -static' } else { '' }
	} $else {
		''
	}
	libbacktrace := $if windows { '' } $else { '-d use_libbacktrace' }
	build_cmd := '${base_build_cmd} ${cc} ${cflags}'.trim_space()
	mut resulting_cmd := match m {
		.release { '${build_cmd} -prod' }
		.debug { '${build_cmd} -g ${libbacktrace}' }
		.dev { '${build_cmd} -d show_ast_on_hover -g ${libbacktrace}' }
	}
	$if !windows {
		// Treesitter's generated C code uses gotos;
		// Older V versions of the json codegen generated `if(cond) \nstatement; statement2;` with wrong indentation, instead of blocks;
		// => Adding the flags below allows v-analyzer to be compiled with -cstrict, and wider range of supported C compilers
		resulting_cmd += ' -cflags "-Wno-misleading-indentation -Wno-jump-misses-init -Wno-error=jump-misses-init -Wno-typedef-redefinition"'
	}
	return resulting_cmd
}

fn prepare_output_dir() string {
	output_dir := './bin'
	if os.exists(output_dir) {
		return output_dir
	}
	os.mkdir(output_dir) or { eline('Failed to create output directory: ${err}') }
	return output_dir
}

fn build(mode ReleaseMode, explicit_debug bool) {
	vexe_version := os.execute('${os.quoted_path(vexe)} version').output.trim_space()
	println('${gcheck} Building with ${vexe_version} .')
	println('${gcheck} Building v-analyzer at commit: ${build_commit} .')
	println('${gcheck} Building start time: ${build_datetime} .')

	odir := prepare_output_dir()
	println('${gcheck} Prepared output directory `${odir}` .')

	cmd := mode.compile_cmd()
	println('Building v-analyzer in ${term.bold(mode.str())} mode, using:')
	println('  ${cmd}')
	if mode == .release {
		println('This may take 1-2 minutes... Please wait.')
	}

	if !explicit_debug && mode == .debug {
		println('')
		println('Note: to build in ${term.bold('release')} mode, run `${term.bold('v build.vsh release')}` .')
		println('    Release mode is recommended for production use.')
		println('    At runtime, it is about 30-40% faster than debug mode.')
		println('')
	}

	os.execute_opt(cmd) or {
		eline('Failed to build v-analyzer')
		eprintln(err)
		exit(1)
	}

	final_path := abs_path(bin_path)
	nbytes := os.file_size(final_path)
	println('The binary size in bytes is: ${nbytes} .')
	println('The binary is located at ${term.bold(final_path)} .')
	elapsed_ms := f64((time.now() - build_time).milliseconds())
	println('${gcheck} Successfully built v-analyzer, in ${elapsed_ms / 1000.0:5.3f}s .')
}

// main program:

os.setenv('BUILD_DATETIME', build_datetime, true)
os.setenv('BUILD_COMMIT', build_commit, true)

mut cmd := cli.Command{
	name:        'v-analyzer-builder'
	version:     metadata.manifest.version
	description: 'Builds the v-analyzer binary.'
	posix_mode:  true
	execute:     fn (_ cli.Command) ! {
		build(.debug, false)
	}
}

// debug builds the v-analyzer binary in debug mode.
// This is the default mode.
// Thanks to -d use_libbacktrace, the binary will print beautiful stack traces,
// which is very useful for debugging.
cmd.add_command(cli.Command{
	name:        'debug'
	description: 'Builds the v-analyzer binary in debug mode.'
	execute:     fn (_ cli.Command) ! {
		build(.debug, true)
	}
})

// dev builds the v-analyzer binary in development mode.
// In this mode, additional development features are enabled.
cmd.add_command(cli.Command{
	name:        'dev'
	description: 'Builds the v-analyzer binary in development mode.'
	execute:     fn (_ cli.Command) ! {
		build(.dev, false)
	}
})

// release builds the v-analyzer binary in release mode.
// This is the recommended mode for production use.
// It is about 30-40% faster than debug mode.
cmd.add_command(cli.Command{
	name:        'release'
	description: 'Builds the v-analyzer binary in release mode.'
	execute:     fn (_ cli.Command) ! {
		build(.release, false)
	}
})

cmd.parse(os.args)
