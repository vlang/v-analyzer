module server

import jsonrpc
import lsp

pub type ResponseWriter = jsonrpc.ResponseWriter

fn (mut wr ResponseWriter) wrap_error(err IError) IError {
	if err is none {
		return err
	}
	wr.log_message(err.msg(), .error)
	return none
}

// log_message sends a window/logMessage notification to the client
pub fn (mut wr ResponseWriter) log_message(message string, typ lsp.MessageType) {
	wr.write_notify('window/logMessage', lsp.LogMessageParams{
		@type:   typ
		message: message
	})
}
