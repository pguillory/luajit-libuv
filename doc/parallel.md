API Reference - parallel
========================

The `parallel` module contains functions for performing computation in
parallel across multiple coroutines. Note that Lua coroutines are not
preemptive. Only one coroutine can run at a time, but they yield to each other
while waiting for I/O requests from `libuv`.

**parallel.map(inputs, callback)**

Map an array of inputs to an array of outputs. Each input is passed to
`callback` in its own coroutine, so that I/O operations are performed in
parallel.

```lua
local requests = {
  { url = 'http://example.com/page1' },
  { url = 'http://example.com/page2' },
}
local responses = parallel.map(requests, http.request)
```

**parallel.range(n, callback)**

Call `callback` `n` times, each in its own coroutine. Like a parallel version
of the `for` loop.
