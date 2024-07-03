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
module intentions

import lsp
import analyzer.psi

pub struct IntentionContext {
	// file where this intention is available.
	containing_file &psi.PsiFile
	// position where this intention is available.
	position lsp.Position
}

pub fn IntentionContext.from(containing_file &psi.PsiFile, position lsp.Position) IntentionContext {
	return IntentionContext{
		containing_file: containing_file
		position: position
	}
}

// Intention actions are invoked by pressing Alt-Enter in the code
// editor at the location where an intention is available.
pub interface Intention {
	// unique id of the intention.
	// This id is equivalent to the id of the command that is
	// invoked when user selects this intention.
	id   string
	name string // name to be shown in the list of available actions, if this action is available.
	// is_available checks whether this intention is available at a caret offset in the file.
	// If this method returns true, a light bulb for this intention is shown.
	is_available(ctx IntentionContext) bool
	// invoke called when user invokes intention. This method is called inside command.
	invoke(ctx IntentionContext) ?lsp.WorkspaceEdit
}
