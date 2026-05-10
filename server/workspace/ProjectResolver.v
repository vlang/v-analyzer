module workspace

import os
import lsp

pub struct ProjectResolver {
	workspace_root string
mut:
	cache shared map[string]string
}

pub fn ProjectResolver.new(workspace_root string) &ProjectResolver {
	return &ProjectResolver{
		workspace_root: os.real_path(workspace_root)
		cache:          map[string]string{}
	}
}

pub fn (mut p ProjectResolver) resolve(uri lsp.DocumentUri) string {
	filepath := os.real_path(uri.path())
	dir := os.dir(filepath)

	rlock p.cache {
		if cached := p.cache[dir] {
			return cached
		}
	}

	root := p.find_root(dir)

	lock p.cache {
		p.cache[dir] = root
	}

	return root
}

pub fn (mut p ProjectResolver) clear() {
	lock p.cache {
		p.cache.clear()
	}
}

fn (p &ProjectResolver) find_root(start_dir string) string {
	mut curr := start_dir
	home_dir := os.home_dir()

	for {
		if os.exists(os.join_path(curr, 'v.mod')) || os.is_dir(os.join_path(curr, '.git'))
			|| curr == p.workspace_root {
			return curr
		}

		parent := os.dir(curr)
		if curr == home_dir || parent == curr {
			break
		}
		curr = parent
	}

	return if start_dir.starts_with(p.workspace_root) {
		p.workspace_root
	} else {
		start_dir
	}
}
