module stubs

// err is a special variable that is set with an error
// and is used to handle errors in V.
//
// It can be used inside two places:
//
// 1. inside `or` block:
// ```
// fn foo() !int {
//   return error("not implemented");
// }
//
// foo() or {
//   panic(err);
//   //    ^^^ err is set with error("not implemented")
// }
// ```
//
// 2. inside else block for if guard:
// ```
// fn foo() !int {
//   return error("not implemented");
// }
//
// if val := foo() {
//   // val is set with int
// } else {
//   panic(err);
//   //    ^^^ err is set with error("not implemented")
// }
// ```
//
// See [Documentation](https://docs.vosca.dev/concepts/error-handling/overview.html)
// for more details.
pub const err = IError{}
