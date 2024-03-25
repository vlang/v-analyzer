module progress

import lsp
import server.protocol

pub struct Tracker {
pub mut:
	support_work_done_progress bool
	client                     &protocol.Client = unsafe { nil }
}

pub fn new_tracker(mut client protocol.Client) &Tracker {
	return &Tracker{
		client: client
	}
}

pub fn (mut t Tracker) start(title string, message string, token lsp.ProgressToken) &WorkDone {
	mut wd := &WorkDone{
		token: token
		client: t.client
	}

	if !t.support_work_done_progress {
		t.client.show_message(message, .log)
		return wd
	}

	if wd.token.empty() {
		new_token := lsp.generate_progress_token()
		t.client.work_done_progress_create(token: new_token)
		wd.token = new_token
	}

	t.client.progress(
		token: wd.token
		value: lsp.WorkDoneProgressPayload{
			kind: 'begin'
			title: title
			message: message
			percentage: 0
			cancellable: false
		}
	)

	return wd
}

@[heap]
pub struct WorkDone {
pub mut:
	token  lsp.ProgressToken
	client &protocol.Client
}

pub fn (mut wd WorkDone) progress(message string, percentage u32) {
	if wd.token.empty() {
		return
	}

	wd.client.progress(
		token: wd.token
		value: lsp.WorkDoneProgressPayload{
			kind: 'report'
			message: message.trim_string_right('\n')
			percentage: percentage
		}
	)
}

pub fn (mut wd WorkDone) end(message string) {
	if wd.token.empty() {
		wd.client.show_message(message, .info)
		return
	}

	wd.client.progress(
		token: wd.token
		value: lsp.WorkDoneProgressPayload{
			kind: 'end'
			message: message
		}
	)
}
