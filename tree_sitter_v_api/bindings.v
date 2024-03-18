module tree_sitter_v_api

import x.json2
import os

#flag -I @VMODROOT/tree_sitter_v_api
#flag -I @VMODROOT/tree_sitter_v/src
#flag @VMODROOT/tree_sitter_v/src/parser.c

#include "bindings.h"

fn C.tree_sitter_v() &TSLanguage

pub const language = unsafe { C.tree_sitter_v() }

// load_node_types reads the node-types.json file for static analysis.
pub fn load_node_types() ![]json2.Any {
	contents := os.read_file(os.join_path(@VMODROOT, 'src', 'node-types.json'))!
	list := json2.raw_decode(contents)!
	return list.arr()
}
