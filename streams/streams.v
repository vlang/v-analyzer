module streams

import term
import net
import os
import io
import loglib

fn C._setmode(int, int)

const content_length = 'Content-Length: '

pub fn new_stdio_stream() io.ReaderWriter {
	stream := &StdioStream{}
	$if windows {
		// 0x8000 = _O_BINARY from <fcntl.h>
		// windows replaces \n => \r\n, so \r\n will be replaced to \r\r\n
		// binary mode prevents this
		C._setmode(C._fileno(C.stdout), 0x8000)
	}
	return stream
}

struct StdioStream {
mut:
	stdin  os.File = os.stdin()
	stdout os.File = os.stdout()
}

pub fn (mut stream StdioStream) write(buf []u8) !int {
	defer {
		stream.stdout.flush()
	}
	return stream.stdout.write(buf)
}

pub fn (mut stream StdioStream) read(mut buf []u8) !int {
	mut header_len := 0
	mut conlen := 0
	for {
		len := read_line(stream.stdin, mut buf) or { return err }
		st := buf.len - len
		line := buf[st..].bytestr()

		buf << `\r`
		buf << `\n`
		header_len = len + 2

		if len == 0 {
			// encounter empty line ('\r\n') in header, header end
			break
		} else if line.starts_with(content_length) {
			conlen = line.all_after(content_length).int()
		}
	}

	mut body := []u8{len: conlen}
	read_cnt := stream.stdin.read(mut body) or { return err }
	if read_cnt != conlen {
		return IError(io.Eof{})
	}
	buf << body

	return header_len + conlen
}

fn read_line(file &os.File, mut buf []u8) !int {
	mut len := 0
	mut temp := []u8{len: 256, cap: 256}
	for {
		read_cnt := file.read_bytes_with_newline(mut temp) or { return err }
		len += read_cnt
		buf << temp[0..read_cnt]
		if read_cnt == 0 {
			return if len == 0 {
				IError(io.Eof{})
			} else {
				len
			}
		}
		if buf.len > 0 && buf.last() == `\n` {
			buf.pop()
			len--
			// check is it just '\n' or '\r\n'
			if len > 0 && buf.last() == `\r` {
				buf.pop()
				len--
			}
			break
		}
	}
	return len
}

const base_ip = '127.0.0.1'

pub fn new_socket_stream_server(port int, log bool) !io.ReaderWriter {
	server_label := 'v-analyzer-server'

	address := '${base_ip}:${port}'
	mut listener := net.listen_tcp(.ip, address)!

	if log {
		eprintln(term.yellow('Warning: TCP connection is used primarily for debugging purposes only \n         and may have performance issues. Use it on your own risk.\n'))
		println('[${server_label}] : Established connection at ${address}\n')
	}

	mut conn := listener.accept() or {
		listener.close() or {}
		return err
	}

	mut reader := io.new_buffered_reader(reader: conn, cap: 1024 * 1024)
	conn.set_blocking(true) or {}

	mut stream := &SocketStream{
		log_label: server_label
		log:       log
		port:      port
		conn:      conn
		reader:    reader
	}

	return stream
}

fn new_socket_stream_client(port int) !io.ReaderWriter {
	address := '${base_ip}:${port}'
	mut conn := net.dial_tcp(address)!
	mut reader := io.new_buffered_reader(reader: conn, cap: 1024 * 1024)
	conn.set_blocking(true) or {}

	mut stream := &SocketStream{
		log_label: 'v-analyzer-client'
		log:       false
		port:      port
		conn:      conn
		reader:    reader
	}
	return stream
}

struct SocketStream {
	log_label string = 'v-analyzer'
	log       bool   = true
mut:
	conn   &net.TcpConn       = &net.TcpConn(net.listen_tcp(.ip, '80')!)
	reader &io.BufferedReader = unsafe { nil }
pub mut:
	port  int = 5007
	debug bool
}

pub fn (mut stream SocketStream) write(buf []u8) !int {
	// TODO: should be an interceptor
	$if !test {
		if stream.log {
			loglib.trace('${term.bg_green('Sent data →')} : ${buf.bytestr()}\n')
		}
	}

	return stream.conn.write(buf)
}

const newlines = [u8(`\r`), `\n`]

@[manualfree]
pub fn (mut stream SocketStream) read(mut buf []u8) !int {
	mut conlen := 0
	mut header_len := 0

	for {
		// read header line
		got_header := stream.reader.read_line() or { return IError(io.Eof{}) }
		buf << got_header.bytes()
		buf << newlines
		header_len = got_header.len + 2

		if got_header.len == 0 {
			// encounter empty line ('\r\n') in header, header end
			break
		} else if got_header.starts_with(content_length) {
			conlen = got_header.all_after(content_length).int()
		}
	}

	if conlen > 0 {
		mut rbody := []u8{len: conlen}
		defer {
			unsafe { rbody.free() }
		}

		for read_data_len := 0; read_data_len != conlen; {
			read_data_len = stream.reader.read(mut rbody) or { return IError(io.Eof{}) }
		}

		buf << rbody
	}

	$if !test {
		if stream.log {
			loglib.trace('${term.green('Received data ←')} : ${buf.bytestr()}\n')
		}
	}
	return conlen + header_len
}
