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
