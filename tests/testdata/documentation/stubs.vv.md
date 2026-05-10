Module: **stubs**
```v
pub type voidptr = voidptr
```

voidptr is an untyped pointer. You can pass any other type of pointer value, to a function that accepts a voidptr.
Mostly used for [C interoperability](https://docs.vosca.dev/advanced-concepts/v-and-c.html).
