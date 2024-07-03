// MIT License
//
// Copyright (c) 2023-2024 V Open Source Community Association (VOSCA) vosca.dev
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
module psi

import v_tree_sitter.tree_sitter
import tree_sitter_v as v

pub type ID = int

pub type AstNode = tree_sitter.Node[v.NodeType]

pub interface PsiElement {
	node            AstNode // base node from Tree Sitter
	containing_file &PsiFile // file where the element is located
	stub_id         StubId
	get_stub() ?&StubBase
	stub_list() &StubList
	element_type() v.NodeType
	node() AstNode // return base node from Tree Sitter
	containing_file() &PsiFile // return file where the element is located
	is_equal(other PsiElement) bool // return true if the element is equal to the other element
	// find_element_at returns the leaf node at the specified position relative to the start of the node.
	// If the node is not found, none is returned.
	find_element_at(offset u32) ?PsiElement
	// find_reference_at returns the reference node at the specified position relative to the start of the node.
	// If the node is not found, none is returned.
	find_reference_at(offset u32) ?PsiElement
	// parent returns the parent node.
	// If the node is the root, none is returned.
	parent() ?PsiElement
	// parent_nth returns the parent node at the specified nesting level.
	// `parent_nth(0)` is equivalent to `parent()`.
	// If no such node exists, none is returned.
	parent_nth(depth int) ?PsiElement
	// parent_of_type returns the parent node with the specified type.
	// If no such node exists, none is returned.
	parent_of_type(typ v.NodeType) ?PsiElement
	// parent_of_any_type returns the parent node with one of the specified types.
	// If no such node exists, none is returned.
	parent_of_any_type(types ...v.NodeType) ?PsiElement
	// inside returns true if the node is inside a node with the specified type.
	inside(typ v.NodeType) bool
	// is_parent_of returns true if the passed node is a child of the given node.
	is_parent_of(element PsiElement) bool
	// sibling_of_type_backward returns the previous node at the same nesting level with the specified type.
	// If no such node exists, none is returned.
	sibling_of_type_backward(typ v.NodeType) ?PsiElement
	// parent_of_type_or_self returns the parent node with the specified type, or the
	// node itself if its type matches the specified one.
	// If no such node exists, none is returned.
	parent_of_type_or_self(typ v.NodeType) ?PsiElement
	// children returns all child nodes.
	children() []PsiElement
	// named_children returns child nodes except unknown nodes.
	named_children() []PsiElement
	// first_child returns the first child node.
	// If the node has no children, none is returned.
	first_child() ?PsiElement
	// first_child_or_stub returns the first child node or stub.
	// If the node has no children or stub, none is returned.
	first_child_or_stub() ?PsiElement
	// last_child returns the last child of the node.
	// If the node has no children, none is returned.
	last_child() ?PsiElement
	// last_child_or_stub returns the last child node or stub.
	// If the node has no children or stub, none is returned.
	last_child_or_stub() ?PsiElement
	// next_sibling returns the next node at the same nesting level.
	// If the node is the last child node, none is returned.
	next_sibling() ?PsiElement
	// next_sibling_or_stub returns the next node at the same nesting level or stub.
	// If the node is the last child node or stub, none is returned.
	next_sibling_or_stub() ?PsiElement
	// prev_sibling returns the previous node at the same nesting level.
	// If the node is the first child node, none is returned.
	prev_sibling() ?PsiElement
	// prev_sibling_of_type returns the previous node at the same nesting level with the specified type.
	// If no such node exists, none is returned.
	prev_sibling_of_type(typ v.NodeType) ?PsiElement
	// prev_sibling_or_stub returns the previous node at the same nesting level or stub.
	// If the node is the first child node or stub, none is returned.
	prev_sibling_or_stub() ?PsiElement
	// find_child_by_type returns the first child node with the specified type.
	// If no such node is found, none is returned.
	find_child_by_type(typ v.NodeType) ?PsiElement
	// has_child_of_type returns true if the node has a child with the specified type.
	has_child_of_type(typ v.NodeType) bool
	// find_child_by_type_or_stub returns the first child node with the specified type or stub.
	// If no such node is found, none is returned.
	find_child_by_type_or_stub(typ v.NodeType) ?PsiElement
	// find_child_by_name returns the first child node with the specified name.
	// If no such node is found, none is returned.
	find_child_by_name(name string) ?PsiElement
	// find_children_by_type returns all child nodes with the specified type.
	// If no such nodes are found, an empty array is returned.
	find_children_by_type(typ v.NodeType) []PsiElement
	// find_children_by_type_or_stub returns all child nodes with the specified type or stub.
	// If no such nodes are found, an empty array is returned.
	find_children_by_type_or_stub(typ v.NodeType) []PsiElement
	// get_text returns the text of the node.
	get_text() string
	// text_matches returns true if the text of the node matches the specified value.
	// This method is more efficient than `get_text() == value`.
	text_matches(value string) bool
	// accept passes the element to the passed visitor.
	accept(visitor PsiElementVisitor)
	// accept_mut passes the element to the passed visitor.
	// Unlike `accept()`, this method uses a visitor that can mutate its state.
	accept_mut(mut visitor MutablePsiElementVisitor)
	// text_range returns the range of the node in the source file.
	text_range() TextRange
	// text_length returns the length of the node's text.
	text_length() int
}
