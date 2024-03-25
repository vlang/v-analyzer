module server

import time
import loglib

type Task = fn ()

enum BackgroundThreadState {
	stopped
	running
}

// BackgroundThread is a simple abstraction a system thread.
// It accepts tasks and executes them in FIFO order.
//
// By executing tasks in a separate thread, we can perform long
// operations without blocking the main thread.
struct BackgroundThread {
	end_ch  chan bool
	task_ch chan Task = chan Task{cap: 20}
mut:
	state BackgroundThreadState
}

// start starts a background thread.
pub fn (mut b BackgroundThread) start() {
	spawn fn [mut b] () {
		b.state = .running
		for {
			select {
				task := <-b.task_ch {
					task()
				}
				_ := <-b.end_ch {
					return
				}
				100 * time.second {
					// wait
				}
			}
		}
	}()
}

// stop stops a background thread.
pub fn (b &BackgroundThread) stop() {
	if b.state == .stopped {
		loglib.warn('Cannot end stopped background thread')
		return
	}

	b.end_ch <- true
}

// queue queues a task to a background thread.
// Tasks will be executed in FIFO order.
pub fn (b &BackgroundThread) queue(cb fn ()) {
	if b.state == .stopped {
		loglib.warn('Cannot queue task to stopped background thread')
		return
	}

	b.task_ch <- cb
}
