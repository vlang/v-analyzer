#!/usr/bin/env -S v

// This script is used to build the v-analyzer binary.
// Usage:
//  v build.vsh [debug|dev|release]
// By default, just `v build.vsh` will use debug mode.
import os
import cli
import time
import term
import v.vmod

const version = vmod.decode(@VMOD_FILE) or { panic(err) }.version
const bin_path = './bin/v-analyzer' + $if windows { '.exe' } $else { '' }

const build_commit = os.execute('git rev-parse --short HEAD').output.trim_space()
const build_datetime = time.now().format_ss()

enum ReleaseMode {
	release
	debug
	dev
}

fn errorln(msg string) {
	eprintln('${term.red('[ERROR]')} ${msg}')
}

fn (m ReleaseMode) compile_cmd() string {
	base_build_cmd := '${@VEXE} ${@VMODROOT} -o ${bin_path} -no-parallel'
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
	} $else $if linux {
		if m == .release { '-cflags -static' } else { '' }
	} $else {
		''
	}
	libbacktrace := $if windows { '' } $else { '-d use_libbacktrace' }
	build_cmd := '${base_build_cmd} ${cc} ${cflags}'
	return match m {
		.release { '${build_cmd} -prod' }
		.debug { '${build_cmd} -g ${libbacktrace}' }
		.dev { '${build_cmd} -d show_ast_on_hover -g ${libbacktrace}' }
	}
}

fn prepare_output_dir() {
	if os.exists('./bin') {
		return
	}
	os.mkdir('./bin') or { errorln('Failed to create output directory: ${err}') }
}

fn generate() ! {
	os.chdir('./tree_sitter_v')!
	os.execute_opt('npm run generate')!
	os.chdir('../')!
}

fn build(mode ReleaseMode, explicit_debug bool) {
	println('Building v-analyzer at commit: ${build_commit}, build time: ${build_datetime} ...')

	generate() or {
		eprintln('Failed to generate tree-sitter grammar. ${err}')
		exit(1)
	}
	println('${term.green('✓')} Generated tree-sitter grammar')

	prepare_output_dir()
	println('${term.green('✓')} Prepared output directory')

	cmd := mode.compile_cmd()
	println('Building v-analyzer in ${term.bold(mode.str())} mode, using: ${cmd}')
	if mode == .release {
		println('This may take a while...')
	}

	if !explicit_debug && mode == .debug {
		println('To build in ${term.bold('release')} mode, run ${term.bold('v build.vsh release')}')
		println('Release mode is recommended for production use. At runtime, it is about 30-40% faster than debug mode.')
	}

	os.execute_opt(cmd) or {
		errorln('Failed to build v-analyzer')
		eprintln(err)
		exit(1)
	}

	println('${term.green('✓')} Successfully built v-analyzer!')
	println('Binary is located at ${term.bold(abs_path(bin_path))}')
}

// main program:

os.setenv('BUILD_DATETIME', build_datetime, true)
os.setenv('BUILD_COMMIT', build_commit, true)

mut cmd := cli.Command{
	name: 'v-analyzer-builder'
	version: version
	description: 'Builds the v-analyzer binary.'
	posix_mode: true
	execute: fn (_ cli.Command) ! {
		build(.debug, false)
	}
}

// debug builds the v-analyzer binary in debug mode.
// This is the default mode.
// Thanks to -d use_libbacktrace, the binary will print beautiful stack traces,
// which is very useful for debugging.
cmd.add_command(cli.Command{
	name: 'debug'
	description: 'Builds the v-analyzer binary in debug mode.'
	execute: fn (_ cli.Command) ! {
		build(.debug, true)
	}
})

// dev builds the v-analyzer binary in development mode.
// In this mode, additional development features are enabled.
cmd.add_command(cli.Command{
	name: 'dev'
	description: 'Builds the v-analyzer binary in development mode.'
	execute: fn (_ cli.Command) ! {
		build(.dev, false)
	}
})

// release builds the v-analyzer binary in release mode.
// This is the recommended mode for production use.
// It is about 30-40% faster than debug mode.
cmd.add_command(cli.Command{
	name: 'release'
	description: 'Builds the v-analyzer binary in release mode.'
	execute: fn (_ cli.Command) ! {
		build(.release, false)
	}
})

cmd.parse(os.args)
