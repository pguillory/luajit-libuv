API Reference - uv.loop
=======================

The `loop` module provides direct control over the libuv event loop.

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

### loop.alive()

Check whether the libuv event loop is running.

### loop.stop()

Stop the libuv event loop.

### loop.idle(callback)

Call `callback` continuously while the event loop has nothing else to do.

### loop.yield(callback)

Call `callback` each time Lua yields control to the event loop.

### loop.resume(callback)

Call `callback` each time Lua resumes control from libuv.
