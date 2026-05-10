module stubs

// `chan` keyword defines a typed channel that is used for communication between
// several threads in multithreaded programs.
//
// Channels are a typed conduit through which you can send and receive values
// with the channel (`<-`) operator.
//
// ```
// ch := chan int{} // channel of ints
// ch2 := chan f64{} // channel of f64s
// ```
//
// Values can be sent to a channel using the arrow operator <-:
//
// ```
// ch <- 5
// ```
//
// Or obtained from a channel:
//
// ```
// i := <-ch
// ```
//
// Learn more about channels in the [documentation](https://docs.vosca.dev/concepts/concurrency/channels.html).
pub struct ChanInit {
pub:
	// cap fields describes the size of the buffered channel.
	//
	// The channel size describes the number of elements that can be
	// written to the channel without blocking.
	// If more elements are written to the channel than the buffer size,
	// then the write is blocked until another thread reads the element
	// from the channel and there is free space.
	//
	// If `cap == 0` (default), then the channel is not buffered.
	//
	// **Example**
	// ```
	// ch := chan int{cap: 10} // buffered channel
	// ch <- 1 // no blocking
	// ```
	//
	// **Example**
	// ```
	// ch := chan int{} // unbuffered channel
	// ch <- 1 // block until another thread reads from the channel
	// ```
	cap int
}
