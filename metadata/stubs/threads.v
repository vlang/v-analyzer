module stubs

// Thread represent `thread T` type.
struct Thread[T] {}

// wait waits for thread to finish and returns its result.
//
// It is a blocking call, and will block the current thread until the thread finishes.
//
// Return type is `T` where `T` is the type of the thread.
// ```
// int_thread := spawn fn () int { return 1 }()
// //                        ^^^ return `int` type
// int_thread.wait() // returns int
//
// arr_string_thread := spawn fn () []string { return ['Hello World'] }()
// //                               ^^^^^^^^ return `[]string` type
// arr_string_thread.wait() // returns []string
// ```
//
// Example:
// ```
// fn expensive_computing(i int) int {
//   return i * i
// }
//
// fn main() {
//   mut thread := spawn expensive_computing(100)
//   //  ^^^^^^ has type `thread int`, because `expensive_computing()` returns `int`
//   result := thread.wait()
//
//   println('Result: ${result}')
//   // Output:
//   // Result: 10000
// }
// ```
//
pub fn (t Thread[T]) wait() T

// ThreadPool represent a pool of threads: `[]thread T` type.
struct ThreadPool[T] {}

// wait waits for all threads in the pool to finish
// and returns result of all threads as array.
//
// It is a blocking call, and will not return until all threads are finished.
//
// Return type is `[]T` where `T` is the type of the thread.
// ```
// mut int_threads := []thread int{}
// //                          ^^^
// int_threads.wait() // returns []int
//
// mut arr_string_threads := []thread []string{}
// //                                 ^^^^^^^^
// arr_string_threads.wait() // returns [][]string
// ```
//
// Example:
// ```
// fn expensive_computing(i int) int {
//   return i * i
// }
//
// fn main() {
//   mut threads := []thread int{}
//   for i in 1 .. 10 {
//     threads << spawn expensive_computing(i)
//   }
//
//   results := threads.wait()
//   println('All jobs finished: ${results}')
//
//   // Output:
//   // All jobs finished: [1, 4, 9, 16, 25, 36, 49, 64, 81]
// }
// ```
//
// See [Documentation](https://docs.vosca.dev/concepts/concurrency.html) for more details.
pub fn (t ThreadPool[T]) wait() []T
