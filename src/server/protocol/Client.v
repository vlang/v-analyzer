module protocol

import jsonrpc
import lsp

@[heap]
pub struct Client {
mut:
	wr jsonrpc.ResponseWriter
}

pub fn new_client(mut wr jsonrpc.ResponseWriter) &Client {
	return &Client{
		wr: wr
	}
}

pub fn (mut c Client) work_done_progress_create(params lsp.WorkDoneProgressCreateParams) {
	c.wr.write_request('window/workDoneProgress/create', params)
}

pub fn (mut c Client) progress(params lsp.ProgressParams) {
	c.wr.write_notify('$/progress', params)
}

// log_message sends a window/logMessage notification to the client
pub fn (mut c Client) log_message(message string, typ lsp.MessageType) {
	$if test {
		if c == unsafe { nil } {
			return
		}
	}
	c.wr.write_notify('window/logMessage', lsp.LogMessageParams{
		@type: typ
		message: message
	})
}

// show_message sends a window/showMessage notification to the client
pub fn (mut c Client) show_message(message string, typ lsp.MessageType) {
	c.wr.write_notify('window/showMessage', lsp.ShowMessageParams{
		@type: typ
		message: message
	})
}

pub fn (mut c Client) show_message_request(message string, actions []lsp.MessageActionItem, typ lsp.MessageType) {
	c.wr.write_notify('window/showMessageRequest', lsp.ShowMessageRequestParams{
		@type: typ
		message: message
		actions: actions
	})
}

pub fn (mut c Client) send_server_status(params lsp.ServerStatusParams) {
	c.wr.write_notify('experimental/serverStatus', params)
}

pub fn (mut c Client) apply_edit(params lsp.ApplyWorkspaceEditParams) {
	c.wr.write_request('workspace/applyEdit', params)
}
