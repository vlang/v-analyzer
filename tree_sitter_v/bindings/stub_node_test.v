module bindings

fn test_stub_node_has_no_native_tree() {
	node := new_stub_node[NodeType](type_factory, NodeType.unknown)
	assert node.type_name == .unknown
	assert node.is_null()
}
