module parser

import sync

pub fn parse_batch_files(files []string, count_workers int) []ParseResult {
	effective_workers := if files.len < count_workers {
		files.len
	} else {
		count_workers
	}

	file_chan := chan string{cap: 1000}
	result_chan := chan ParseResult{cap: 1000}

	spawn fn [file_chan, files] () {
		for file in files {
			file_chan <- file
		}
		file_chan.close()
	}()

	spawn spawn_parser_workers(result_chan, file_chan, effective_workers)

	mut results := []ParseResult{cap: 100}
	for {
		result := <-result_chan or { break }
		results << result
	}
	return results
}

fn spawn_parser_workers(result_chan chan ParseResult, file_chan chan string, count_workers int) {
	mut wg := sync.new_waitgroup()
	wg.add(count_workers)
	for i := 0; i < count_workers; i++ {
		spawn fn [file_chan, mut wg, result_chan] () {
			for {
				filepath := <-file_chan or { break }
				mut result := parse_file(filepath) or { continue }
				result.path = filepath
				result_chan <- result
			}

			wg.done()
		}()
	}

	wg.wait()
	result_chan.close()
}
