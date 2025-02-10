module bindings

pub type TSParser = C.TSParser
pub type TSLanguage = C.TSLanguage

pub const language = unsafe { &TSLanguage(C.tree_sitter_v()) }

pub struct Parser[T] {
mut:
	raw_parser   &TSParser = unsafe { nil }          @[required]
	type_factory NodeTypeFactory[T] @[required]
}

pub fn new_parser[T](type_factory NodeTypeFactory[T]) &Parser[T] {
	mut parser := new_ts_parser()
	return &Parser[T]{
		raw_parser:   parser
		type_factory: type_factory
	}
}

@[inline]
pub fn (mut p Parser[T]) set_language(language &TSLanguage) {
	p.raw_parser.set_language(language)
}

@[inline]
pub fn (mut p Parser[T]) reset() {
	p.raw_parser.reset()
}

@[params]
pub struct ParseConfig {
pub:
	source string @[required]
	tree   &TSTree = &TSTree(unsafe { nil })
}

pub fn (mut p Parser[T]) parse_string(cfg ParseConfig) &Tree[T] {
	tree := p.raw_parser.parse_string_with_old_tree(cfg.source, cfg.tree)
	return &Tree[T]{
		raw_tree:     tree
		type_factory: p.type_factory
	}
}

pub interface NodeTypeFactory[T] {
	get_type(type_name string) T
}

pub struct Tree[T] {
	type_factory NodeTypeFactory[T] @[required]
pub:
	raw_tree &TSTree = unsafe { nil } @[required]
}

@[unsafe]
pub fn (tree &Tree[T]) free() {
	unsafe { tree.raw_tree.free() }
}

pub fn (tree Tree[T]) root_node() Node[T] {
	return new_tsnode[T](tree.type_factory, tree.raw_tree.root_node())
}

pub fn new_tsnode[T](factory NodeTypeFactory[T], node TSNode) Node[T] {
	return Node[T]{
		raw_node:     node
		type_factory: factory
		type_name:    factory.get_type(node.type_name())
	}
}

pub struct Node[T] {
	type_factory NodeTypeFactory[T] @[required]
pub:
	raw_node  TSNode @[required]
	type_name T      @[required]
}

@[inline]
pub fn (node Node[T]) text(text string) string {
	return node.raw_node.text(text)
}

@[inline]
pub fn (node Node[T]) text_matches(all_text string, text_to_find string) bool {
	text_len := u32(text_to_find.len)
	node_len := node.text_length()

	// if the text we are looking for does not match in length,
	// then the text cannot exactly match
	if text_len != node_len {
		return false
	}

	return node.text(all_text) == text_to_find
}

@[inline]
pub fn (node Node[T]) first_char(text string) u8 {
	start_index := node.start_byte()
	if start_index >= u32(text.len) {
		return 0
	}
	return text[start_index]
}

@[inline]
pub fn (node Node[T]) text_length() u32 {
	start := node.raw_node.start_byte()
	end := node.raw_node.end_byte()
	return end - start
}

@[inline]
pub fn (node Node[T]) str() string {
	return node.raw_node.sexpr_str()
}

@[inline]
pub fn (node Node[T]) start_point() TSPoint {
	return node.raw_node.start_point()
}

@[inline]
pub fn (node Node[T]) end_point() TSPoint {
	return node.raw_node.end_point()
}

@[inline]
pub fn (node Node[T]) start_byte() u32 {
	return node.raw_node.start_byte()
}

@[inline]
pub fn (node Node[T]) end_byte() u32 {
	return node.raw_node.end_byte()
}

@[inline]
pub fn (node Node[T]) range() TSRange {
	return node.raw_node.range()
}

@[inline]
pub fn (node Node[T]) is_null() bool {
	return node.raw_node.is_null()
}

@[inline]
pub fn (node Node[T]) is_leaf() bool {
	return node.child_count() == 0
}

@[inline]
pub fn (node Node[T]) is_named() bool {
	return node.raw_node.is_named()
}

@[inline]
pub fn (node Node[T]) is_missing() bool {
	return node.raw_node.is_missing()
}

@[inline]
pub fn (node Node[T]) is_extra() bool {
	return node.raw_node.is_extra()
}

@[inline]
pub fn (node Node[T]) has_changes() bool {
	return node.raw_node.has_changes()
}

@[inline]
pub fn (node Node[T]) is_error() bool {
	return node.raw_node.is_error()
}

pub fn (node Node[T]) parent() ?Node[T] {
	parent := node.raw_node.parent()?
	return new_tsnode[T](node.type_factory, parent)
}

pub fn (node Node[T]) parent_nth(depth int) ?Node[T] {
	mut res := node.raw_node
	for _ in 0 .. depth {
		res = res.parent()?
	}
	return new_tsnode[T](node.type_factory, res)
}

pub fn (node Node[T]) is_parent_of(other Node[T]) bool {
	mut parent := other.parent() or { return false }

	for {
		if parent.equal(node) {
			return true
		}
		parent = parent.parent() or { break }
	}

	return false
}

pub fn (node Node[T]) child(pos u32) ?Node[T] {
	child := node.raw_node.child(pos)?
	return new_tsnode[T](node.type_factory, child)
}

@[inline]
pub fn (node Node[T]) child_count() u32 {
	return node.raw_node.child_count()
}

pub fn (node Node[T]) named_child(pos u32) ?Node[T] {
	child := node.raw_node.named_child(pos)?
	return new_tsnode[T](node.type_factory, child)
}

@[inline]
pub fn (node Node[T]) named_child_count() u32 {
	return node.raw_node.named_child_count()
}

pub fn (node Node[T]) child_by_field_name(name string) ?Node[T] {
	child := node.raw_node.child_by_field_name(name)?
	return new_tsnode[T](node.type_factory, child)
}

pub fn (node Node[T]) first_child() ?Node[T] {
	count_child := node.child_count()
	if count_child == 0 {
		return none
	}
	child := node.raw_node.child(0) or { return none }
	return new_tsnode[T](node.type_factory, child)
}

pub fn (node Node[T]) last_child() ?Node[T] {
	count_child := node.child_count()
	if count_child == 0 {
		return none
	}
	child := node.raw_node.child(count_child - 1) or { return none }
	return new_tsnode[T](node.type_factory, child)
}

pub fn (node Node[T]) next_sibling() ?Node[T] {
	sibling := node.raw_node.next_sibling() or { return none }
	return new_tsnode[T](node.type_factory, sibling)
}

pub fn (node Node[T]) prev_sibling() ?Node[T] {
	sibling := node.raw_node.prev_sibling() or { return none }
	return new_tsnode[T](node.type_factory, sibling)
}

pub fn (node Node[T]) next_named_sibling() ?Node[T] {
	sibling := node.raw_node.next_named_sibling() or { return none }
	return new_tsnode[T](node.type_factory, sibling)
}

pub fn (node Node[T]) prev_named_sibling() ?Node[T] {
	sibling := node.raw_node.prev_named_sibling() or { return none }
	return new_tsnode[T](node.type_factory, sibling)
}

pub fn (node Node[T]) first_child_for_byte(offset u32) ?Node[T] {
	child := node.raw_node.first_child_for_byte(offset) or { return none }
	return new_tsnode[T](node.type_factory, child)
}

pub fn (node Node[T]) first_named_child_for_byte(offset u32) ?Node[T] {
	child := node.raw_node.first_named_child_for_byte(offset) or { return none }
	return new_tsnode[T](node.type_factory, child)
}

pub fn (node Node[T]) descendant_for_byte_range(start_range u32, end_range u32) ?Node[T] {
	desc := node.raw_node.descendant_for_byte_range(start_range, end_range) or { return none }
	return new_tsnode[T](node.type_factory, desc)
}

pub fn (node Node[T]) descendant_for_point_range(start_point TSPoint, end_point TSPoint) ?Node[T] {
	desc := node.raw_node.descendant_for_point_range(start_point, end_point) or { return none }
	return new_tsnode[T](node.type_factory, desc)
}

pub fn (node Node[T]) named_descendant_for_byte_range(start_range u32, end_range u32) ?Node[T] {
	desc := node.raw_node.named_descendant_for_byte_range(start_range, end_range) or { return none }
	return new_tsnode[T](node.type_factory, desc)
}

pub fn (node Node[T]) named_descendant_for_point_range(start_point TSPoint, end_point TSPoint) ?Node[T] {
	desc := node.raw_node.named_descendant_for_point_range(start_point, end_point) or {
		return none
	}
	return new_tsnode[T](node.type_factory, desc)
}

pub fn (node Node[T]) first_node_by_type(type_name T) ?Node[T] {
	mut named_child := node.named_child(0) or { return none }
	len := node.child_count()
	for i := 0; i < int(len); i++ {
		if named_child.type_name == type_name {
			return named_child
		}
		named_child = named_child.next_sibling() or { continue }
	}
	return none
}

pub fn (node Node[T]) last_node_by_type(type_name T) ?Node[T] {
	len := node.child_count()
	mut named_child := node.named_child(len - 1) or { return none }
	for i := int(len - 1); i >= 0; i-- {
		if named_child.type_name == type_name {
			return named_child
		}
		named_child = named_child.prev_sibling() or { continue }
	}
	return none
}

@[inline]
pub fn (node Node[T]) == (other_node Node[T]) bool {
	return C.ts_node_eq(node.raw_node, other_node.raw_node)
}

@[inline]
pub fn (node Node[T]) equal(other_node Node[T]) bool {
	return C.ts_node_eq(node.raw_node, other_node.raw_node)
}

@[inline]
pub fn (node Node[T]) tree_cursor() TreeCursor[T] {
	return TreeCursor[T]{
		type_factory: node.type_factory
		raw_cursor:   node.raw_node.tree_cursor()
	}
}

pub struct TreeCursor[T] {
	type_factory NodeTypeFactory[T] @[required]
pub mut:
	raw_cursor C.TSTreeCursor @[required]
}

@[inline]
pub fn (mut cursor TreeCursor[T]) reset(node Node[T]) {
	cursor.raw_cursor.reset(node.raw_node)
}

@[inline]
pub fn (cursor TreeCursor[T]) current_node() ?Node[T] {
	got_node := cursor.raw_cursor.current_node()?
	return new_tsnode[T](cursor.type_factory, got_node)
}

@[inline]
pub fn (cursor TreeCursor[T]) current_field_name() string {
	return cursor.raw_cursor.current_field_name()
}

@[inline]
pub fn (mut cursor TreeCursor[T]) to_parent() bool {
	return cursor.raw_cursor.to_parent()
}

@[inline]
pub fn (mut cursor TreeCursor[T]) next() bool {
	return cursor.raw_cursor.next()
}

@[inline]
pub fn (mut cursor TreeCursor[T]) to_first_child() bool {
	return cursor.raw_cursor.to_first_child()
}

pub type TSRange = C.TSRange

pub fn (r TSRange) str() string {
	return '
{
    start: ${TSPoint(r.start_point)}
    end: ${TSPoint(r.end_point)}
    start_byte: ${r.start_byte}
    end_byte: ${r.end_byte}
}
'.trim_indent()
}

pub type TSPoint = C.TSPoint

pub fn (p TSPoint) str() string {
	return '(${p.row}, ${p.column})'
}
