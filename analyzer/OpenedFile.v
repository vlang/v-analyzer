module analyzer

import lsp
import utils
import analyzer.psi

pub struct OpenedFile {
pub mut:
	uri      lsp.DocumentUri
	version  int
	psi_file &psi.PsiFile
}

pub fn (f OpenedFile) find_offset(pos lsp.Position) u32 {
	return u32(utils.compute_offset(f.psi_file.text(), pos.line, pos.character))
}
