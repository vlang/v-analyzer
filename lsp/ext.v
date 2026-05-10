module lsp

pub struct ServerStatusParams {
pub:
	health    string // "ok" | "warning" | "error";
	quiescent bool
	message   string @[omitempty]
}
