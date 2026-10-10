module server

import jsonrpc
import lsp

pub type ResponseWriter = jsonrpc.ResponseWriter

fn (mut wr ResponseWriter) wrap_error(err IError) IError {
	if err is none || err is jsonrpc.NullResult {
		return jsonrpc.null_result
	}
	wr.log_message(err.msg(), .error)
	return jsonrpc.null_result
}

// log_message sends a window/logMessage notification to the client
pub fn (mut wr ResponseWriter) log_message(message string, typ lsp.MessageType) {
	wr.write_notify('window/logMessage', lsp.LogMessageParams{
		@type:   typ
		message: message
	})
}
