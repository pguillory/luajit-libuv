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

### loop.run()

Run the libuv event loop. This is only necessary if an I/O request was created
in a coroutine without the event loop already running. Requests made outside a
coroutine are performed synchronously. It returns when the last I/O request is
finished.

```lua
print(uv.fs.readfile('README.md'))
```

In this example, we're not in a coroutine, so `fs.readfile` ran the event loop
implicitly. There is no need to call `loop.run()`.

```lua
coroutine.resume(coroutine.create(function()
  print(uv.fs.readfile('README.md'))
end))
loop.run()
```

Here, we manually created a coroutine that called `fs.readfile`, which yielded
while awaiting the result. The event loop is not running, so unless we called
`loop.run()`, the program would exit without performing the I/O request and the
coroutine would never resume.

### uv.alive()

Check whether the libuv event loop is running.

### uv.stop()

Stop the libuv event loop.

### uv.free_memory()

Returns the amount of free memory available to the system, in bytes.

### uv.total_memory()

Returns the total amount of memory in the system, in bytes.

### uv.hrtime()

Returns a high-resolution time in nanoseconds. It is useful for measuring
intervals but not for determining the current clock time.

### uv.loadavg()

Returns the system load average over 1, 5, and 15 minutes. The load average is
the average number of jobs in the run queue.

### uv.uptime()

Returns the number of seconds since the system booted.
