API Reference - uv
==================

The base `uv` module contains utility functions and references to the
submodules. For instance, the `fs` module can be accessed in two ways:

```lua
local fs = require 'uv.fs'
-- or
local uv = require 'uv'
local fs = uv.fs
```

**uv.run()**

Run the libuv event loop. This is only necessary if an I/O request was created
in a coroutine without the event loop already running. Requests made outside a
coroutine are performed synchronously. It returns when the last I/O request is
finished.

```lua
print(uv.fs.readfile('README.md'))
```

In this example, we're not in a coroutine, so `fs.readfile` ran the event loop
implicitly. There is no need to call `uv.run()`.

```lua
coroutine.resume(coroutine.create(function()
  print(uv.fs.readfile('README.md'))
end))
uv.run()
```

Here, we manually created a coroutine that called `fs.readfile`, which yielded
while awaiting the result. The event loop is not running, so unless we called
`uv.run()`, the program would exit without performing the I/O request and the
coroutine would never resume.

