API Reference - process
=======================

The `process` module provides functions for managing the current process.

### process.pid()

Returns the current process's PID.

### process.path()

Returns the path to the executable for the current process.

### process.kill(pid, signal)

Send a signal to a process. `signal` defaults to "SIGKILL" and can have any of
the following values:

- "SIGKILL": The process should exit.
- "SIGINT": The user pressed Control+C.
- "SIGHUP": The user closed the console window.
- "SIGWINCH": The user resized the console window.

### process.on(signal, callback)

Call `callback` when a given signal is received. `signal` can only be "SIGINT", "SIGHUP", or "SIGWINCH".

```lua
process.on('SIGINT', function()
  print('Shutting down...')
  uv.stop()
end)
```
