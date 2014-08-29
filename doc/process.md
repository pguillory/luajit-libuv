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

### process.usage()

Returns a table describing the current process's resource usage with the
following keys:

- `utime`: User CPU time used, in microseconds.
- `stime`: System CPU time used, in microseconds.
- `maxrss`: Maximum resident set size.
- `ixrss`: Integral shared memory size.
- `idrss`: Integral unshared data size.
- `isrss`: Integral unshared stack size.
- `minflt`: Page reclaims (soft page faults).
- `majflt`: Page faults (hard page faults).
- `nswap`: Swaps.
- `inblock`: Block input operations.
- `oublock`: Block output operations.
- `msgsnd`: IPC messages sent.
- `msgrcv`: IPC messages received.
- `nsignals`: Signals received.
- `nvcsw`: Voluntary context switches.
- `nivcsw`: Involuntary context switches.

### process.title(value)

Change the current process's title to `value`, if present. Returns the
existing title. I think this only works on Windows.
