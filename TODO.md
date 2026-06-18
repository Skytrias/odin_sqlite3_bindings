- [X] Have cstring & [^]u8 versions of procs that take optional NULL term
- [X] Convert `c.int` to `Result` where needed
- [ ] Align Things `:)`

```odin
package main

main :: proc() {
    a: cstring = "Hello cstring"
    b := "Hello buffer"
    foo(a, len(a))
    foo(raw_data(b), len(b))
}

foreign import tt "./tt/tt.lib"
foreign tt {
    @(link_name="foo")
    foo_cstring :: proc "odin" (a: cstring, n: int) --- 
    @(link_name="foo")
    foo_buffer  :: proc "odin" (a: [^]u8, n: int) --- 
}

foo :: proc { foo_cstring, foo_buffer }
```

